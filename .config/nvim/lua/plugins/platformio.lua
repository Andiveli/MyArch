return {
    "sbatin/platformio.nvim",
    dependencies = { "numToStr/FTerm.nvim" },
    lazy = true,
    cmd = { "PioBuild", "PioRun", "PioUpload", "PioTest", "PioInit" },
}
