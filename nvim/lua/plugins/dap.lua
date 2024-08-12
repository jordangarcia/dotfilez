return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mfussenegger/nvim-dap-python",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
      "williamboman/mason.nvim",
    },
    keys = {
      {
        "<leader>db",
        "<cmd> lua require('dap').toggle_breakpoint()  <CR>",
        desc = "Toggle breakpoint",
      },
      {
        "<leader>dg",
        "<cmd> lua require('dap').run_to_cursor()  <CR>",
        desc = "Run to cursor",
      },
      {
        "<leader>d?",
        "<cmd> lua require('dapui').eval(nil, { enter = true })  <CR>",
        desc = "Eval",
      },
      {
        "<leader>d1",
        "<cmd> lua require('dap').continue()  <CR>",
        desc = "Continue",
      },
      {
        "<leader>d2",
        "<cmd> lua require('dap').step_into()  <CR>",
        desc = "Step into",
      },
      {
        "<leader>d3",
        "<cmd> lua require('dap').step_over()  <CR>",
        desc = "Step over",
      },
      {
        "<leader>d4",
        "<cmd> lua require('dap').step_out()  <CR>",
        desc = "Step out",
      },
      {
        "<leader>d5",
        "<cmd> lua require('dap').step_back()  <CR>",
        desc = "Step back",
      },
      {
        "<leader>d6",
        "<cmd> lua require('dap').restart()  <CR>",
        desc = "Restart",
      },
      {
        "<leader>d?",
        '<cmd> lua require("dapui").eval(nil, { enter = true })  <CR>',
        desc = "Eval",
      },
      {
        "<leader>dx",
        function()
          local dap = require "dap"
          dap.terminate()
        end,
        "terminate",
      },
      {
        "<leader>da",
        function()
          local dap = require "dap"
          dap.run(dap.configurations.python[5])
        end,
      },
      {
        "<leader>dl",
        function()
          require("dap").show_log()
        end,
        desc = "Show log",
      },
      {
        "<leader>dp",
        function()
          local dap = require "dap"
          dap.run {
            type = "python",
            request = "launch",
            name = "PDM Run Python File",
            program = "pdm run python ${file}",
            args = {},
            pythonPath = function()
              local python = vim.fn.system("pdm info --python"):gsub("\n", "")
              return python
            end,
            env = {
              PYTHONPATH = "src",
            },
            console = "integratedTerminal",
          }
        end,
        desc = "Debug: PDM Run Python File",
      },
    },
    config = function()
      local dap = require "dap"
      local ui = require "dapui"

      require("dapui").setup()
      require("dap-python").setup()

      table.insert(dap.configurations.python, {
        type = "python",
        request = "attach",
        name = "Attach to existing debugpy",
        connect = {
          host = "127.0.0.1",
          port = 5678,
        },
        mode = "remote",
        cwd = vim.fn.getcwd(),
        pathMappings = {
          {
            localRoot = vim.fn.getcwd(),
            remoteRoot = ".",
          },
        },
      })

      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        ui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        ui.close()
      end
    end,
  },
}
