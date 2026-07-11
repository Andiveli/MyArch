return {
    "mistricky/codesnap.nvim",
    tag = "v2.0.0-beta.17",
    cmd = "CodeSnap",
    opts = {
        save_file_path = "~/Pictures/codesnaps",
    },
    keys = {
        { "<leader>ts", "<cmd>CodeSnap<cr>", desc = "CodeSnap: Take Screenshot" },
    },
}
