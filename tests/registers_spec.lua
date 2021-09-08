-- Create a neovim buffer
local function setup_buffer(input)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_command("buffer " .. buf)

    vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.split(input, "\n"))
end

-- Go to the line number and "press" the keys
local function run_keys_on_line(line, feedkeys, mode)
    -- Default to executing commands until typeahead is empty
    mode = mode or "x"

    -- Place the cursor on the line to execute the keys
    vim.api.nvim_win_set_cursor(0, {line,0})

    -- Convert keycodes to keys that can be pressed
    local keys = vim.api.nvim_replace_termcodes(feedkeys, true, false, true)

    -- "Press" the keys
    vim.api.nvim_feedkeys(keys, mode, false)
end

-- Get all lines from the buffer
local function get_buf_lines()
    return vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
end

-- Assert that the buffer contains the following string
local function assert_result_contains(expected)
    local result = get_buf_lines()

    assert.truthy(vim.tbl_contains(result, expected), result)
end

-- Go to the line number, "press" the eys and assert the result
local function run_keys_and_assert(line, feedkeys, expected, mode)
    run_keys_on_line(line, feedkeys, mode)

    local result = get_buf_lines()
    assert.are.same(vim.split(expected, "\n"), result)
end

describe("normal-mode", function()
    it("should paste the registers in the proper position", function()
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

describe(":registers", function()
    before_each(function()
        -- Create the initial buffer
        setup_buffer([[
foo
bar
        ]])
    end)

    describe("copying a single line", function()
        -- Copy the first line into a register
        run_keys_on_line(1, "\"ayy")

        it("should show in the registers window", function()
            -- Open the registers window
            vim.api.nvim_command("lua require'registers'.registers('n')")

            -- Verify that the register window contains our pasted line
            assert_result_contains("a: foo")
        end)
    end)

    describe("copying two lines with '\"a2yy'", function()
        describe("using a custom newline symbol", function()
            -- Set a custom newline symbol
            vim.api.nvim_command("let g:registers_return_symbol='#'")

            it("should show in the registers window", function()
                -- TODO: why can't this be placed in the second describe?
                -- Copy the two line into a register
                run_keys_on_line(1, "\"a2yy")

                -- Open the registers window
                vim.api.nvim_command("lua require'registers'.registers('n')")

                -- Verify that the register window contains our pasted line
                assert_result_contains("a: foo#bar")
            end)
        end)
    end)

    describe("copying two lines with '2\"ayy'", function()
        describe("using a custom newline symbol", function()
            -- Set a custom newline symbol
            vim.api.nvim_command("let g:registers_return_symbol='#'")

            it("should show in the registers window", function()
                -- TODO: why can't this be placed in the second describe?
                -- Copy the two line into a register
                run_keys_on_line(1, "2\"ayy")

                -- Open the registers window
                vim.api.nvim_command("lua require'registers'.registers('n')")

                -- Verify that the register window contains our pasted line
                assert_result_contains("a: foo#bar")
            end)
        end)
    end)
end)
