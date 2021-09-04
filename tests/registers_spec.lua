-- Create a neovim buffer
local function setup_buffer(input)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_command("buffer " .. buf)

    vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.split(input, "\n"))
end

-- Go to the line number and "press" the keys
local function run_keys_on_line(line, feedkeys)
    vim.api.nvim_win_set_cursor(0, {line,0})

    local keys = vim.api.nvim_replace_termcodes(feedkeys, true, false, true)
    vim.api.nvim_feedkeys(keys, "x", false)
end

-- Get all lines from the buffer
local function get_buf_lines()
    local result = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)

    return result
end

-- Go to the line number, "press" the eys and assert the result
local function run_keys_and_assert(line, feedkeys, expected)
    run_keys_on_line(line, feedkeys)

    local result = get_buf_lines()
    assert.are.same(vim.split(expected, "\n"), result)
end

describe("normal-mode", function()
    it("Should paste the registers in the proper position", function()
        -- Create the initial buffer
        setup_buffer([[
foo
bar
        ]])

        -- Copy the first line into a register
        run_keys_on_line(1, "\"ayy")

        -- Paste the register
        run_keys_and_assert(2, "\"ap", [[
foo
bar
foo
        ]])
    end)
end)
