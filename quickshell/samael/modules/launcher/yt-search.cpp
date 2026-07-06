#include <curl/curl.h>
#include <nlohmann/json.hpp>
#include <iostream>
#include <string>
#include <functional>

using json = nlohmann::json;

static size_t write_cb(void *data, size_t size, size_t nmemb, void *userp) {
  auto *str = static_cast<std::string *>(userp);
  auto total = size * nmemb;
  str->append(static_cast<char *>(data), total);
  return total;
}

static std::string url_encode(const std::string &s) {
  CURL *curl = curl_easy_init();
  if (!curl) return s;
  char *enc = curl_easy_escape(curl, s.c_str(), s.size());
  std::string out(enc);
  curl_free(enc);
  curl_easy_cleanup(curl);
  return out;
}

static json search_key(const json &node, const std::string &key) {
  if (node.is_object()) {
    auto it = node.find(key);
    if (it != node.end()) return *it;
    for (auto &[k, v] : node.items()) {
      auto r = search_key(v, key);
      if (!r.is_null()) return r;
    }
  }
  if (node.is_array()) {
    for (auto &v : node)
      if (!v.is_null()) { auto r = search_key(v, key); if (!r.is_null()) return r; }
  }
  return nullptr;
}

struct CurlHandle {
  CURL *handle = nullptr;

  bool init() {
    handle = curl_easy_init();
    if (!handle) return false;

    curl_easy_setopt(handle, CURLOPT_ACCEPT_ENCODING, "");
    curl_easy_setopt(handle, CURLOPT_WRITEFUNCTION, write_cb);
    curl_easy_setopt(handle, CURLOPT_USERAGENT,
      "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36");
    curl_easy_setopt(handle, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(handle, CURLOPT_TIMEOUT, 10L);
    curl_easy_setopt(handle, CURLOPT_CONNECTTIMEOUT, 3L);
    curl_easy_setopt(handle, CURLOPT_TCP_FASTOPEN, 1L);
    curl_easy_setopt(handle, CURLOPT_DNS_CACHE_TIMEOUT, 300L);
    curl_easy_setopt(handle, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
    curl_easy_setopt(handle, CURLOPT_BUFFERSIZE, 256L * 1024L);

    curl_easy_setopt(handle, CURLOPT_SSL_ENABLE_ALPN, 1L);

    // Try HTTP/3 first (QUIC — eliminates TCP+TLS handshake)
    // Falls back to HTTP/2 automatically if H3 is unavailable
    // Keep HTTP/2 — more reliable and similar speed. HTTP/3 (QUIC) adds
    // complexity (UDP NAT issues, firewall blocks) with marginal gain here
    // since the persistent process reuses the connection anyway.
    curl_easy_setopt(handle, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_2_0);
    return true;
  }

  std::string fetch(const std::string &url) {
    std::string buf;
    curl_easy_setopt(handle, CURLOPT_URL, url.c_str());
    curl_easy_setopt(handle, CURLOPT_WRITEDATA, &buf);
    curl_easy_perform(handle);
    return buf;
  }

  ~CurlHandle() { if (handle) curl_easy_cleanup(handle); }
};

static std::string extract_yt_initial_data(const std::string &html) {
  auto start = html.find("var ytInitialData = ");
  if (start == std::string::npos) return {};
  start += 20;
  if (start >= html.size() || html[start] != '{') return {};
  int depth = 0;
  size_t end = start;
  for (; end < html.size(); end++) {
    if (html[end] == '{') depth++;
    else if (html[end] == '}') { depth--; if (depth == 0) { end++; break; } }
  }
  if (depth != 0) return {};
  return html.substr(start, end - start);
}

static json parse_results(const std::string &html) {
  std::string json_str = extract_yt_initial_data(html);
  if (json_str.empty()) return json::array();

  json data;
  try { data = json::parse(json_str); }
  catch (...) { return json::array(); }

  json out = json::array();
  auto contents = search_key(data, "itemSectionRenderer");
  if (contents.is_null() || !contents.is_object()) return out;

  auto items = contents["contents"];
  if (!items.is_array()) return out;

  for (auto &item : items) {
    auto vr = item["videoRenderer"];
    if (vr.is_null()) continue;

    auto video_id = vr["videoId"].get<std::string>();
    auto title = vr["title"]["runs"][0]["text"].get<std::string>();
    auto author = vr["ownerText"]["runs"][0]["text"].get<std::string>();
    std::string duration;
    auto lt = vr["lengthText"];
    if (!lt.is_null())
      duration = lt["simpleText"].get<std::string>();

    out.push_back({
      {"id", video_id},
      {"title", title},
      {"author", author},
      {"duration", duration},
    });
  }

  return out;
}

static void search_and_print(CurlHandle &curl, const std::string &query) {
  std::string url = "https://www.youtube.com/results?search_query="
                  + url_encode(query);
  std::string html = curl.fetch(url);

  if (html.empty()) {
    std::cout << "[]\n" << std::flush;
    return;
  }

  json results = parse_results(html);
  std::cout << results.dump() << "\n" << std::flush;
}

int main(int argc, char **argv) {
  std::ios::sync_with_stdio(false);
  std::cin.tie(nullptr);

  CurlHandle curl;
  if (!curl.init()) {
    std::cerr << "Failed to init CURL\n";
    return 1;
  }

  // Support both argv and stdin modes:
  //   yt-search "query"      — single query via argv (compat with current QML)
  //   echo "query" | yt-search  — stdin loop (persistent mode)
  if (argc >= 2) {
    std::string query = argv[1];
    for (int i = 2; i < argc; i++) query += " " + std::string(argv[i]);
    search_and_print(curl, query);
  } else {
    std::string query;
    while (std::getline(std::cin, query)) {
      if (query.empty()) {
        std::cout << "[]\n" << std::flush;
        continue;
      }
      search_and_print(curl, query);
    }
  }

  return 0;
}
