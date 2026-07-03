-- ==========================================
-- NEOVIM CONFIGURATION - TEMA LAVENDER DREAM
-- ==========================================

-- --- CONFIGURAÇÕES BÁSICAS ---
vim.opt.number = true             -- Exibe números de linha
vim.opt.relativenumber = true     -- Números relativos para facilitar saltos
vim.opt.mouse = 'a'               -- Habilita suporte ao mouse
vim.opt.ignorecase = true         -- Busca insensível a maiúsculas/minúsculas
vim.opt.smartcase = true          -- Sensível caso use maiúscula na busca
vim.opt.hlsearch = false          -- Não destacar todas as correspondências após busca
vim.opt.tabstop = 4               -- Número de espaços que um Tab representa
vim.opt.shiftwidth = 4            -- Espaços usados para auto-indentação
vim.opt.expandtab = true          -- Converte Tab em espaços
vim.opt.smartindent = true        -- Indentação inteligente
vim.opt.termguicolors = true      -- Cores de 24 bits
vim.opt.clipboard = 'unnamedplus' -- Integra com a área de transferência do sistema
vim.g.mapleader = ' '             -- Define a tecla Leader como Espaço

-- --- INSTALADOR AUTOMÁTICO DO LAZY.NVIM ---
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- --- PLUGINS ---
require("lazy").setup({
  -- Tema Catppuccin
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "macchiato", -- Macchiato com detalhes roxo/lavanda
        transparent_background = true, -- Combina com a transparência do terminal
        integrations = {
          treesitter = true,
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
            },
          },
        },
      })
    end
  },

  -- Barra de Status Minimalista (Lualine)
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
          component_separators = '|',
          section_separators = '',
        }
      })
    end
  },

  -- Realce de Sintaxe Avançado (Treesitter)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local status, configs = pcall(require, "nvim-treesitter.configs")
      if status then
        configs.setup({
          ensure_installed = { "lua", "vim", "bash", "python", "json", "yaml", "html", "css", "javascript" },
          highlight = { enable = true },
        })
      end
    end
  },

  -- Fechamento automático de parênteses/colchetes
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true
  },

  -- Marcador de alterações Git na lateral (Gitsigns)
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require('gitsigns').setup()
    end
  },

  -- Localizador Fuzzy (Telescope)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "node_modules", ".git" },
        }
      })
    end
  },

  -- Tela de Inicialização (Alpha Dashboard)
  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")
      
      -- Cabeçalho minimalista em ASCII
      dashboard.section.header.val = {
        "        󰣇        ",
        "       /\\       ",
        "      /  \\      ",
        "     /    \\     ",
        "    /  __  \\    ",
        "   /__/  \\__\\   ",
        "                ",
        "L A V E N D E R"
      }
      
      dashboard.section.buttons.val = {
        dashboard.button("e", "  Novo Arquivo", ":ene <BAR> startinsert <CR>"),
        dashboard.button("f", "  Procurar Arquivo", ":Telescope find_files <CR>"),
        dashboard.button("r", "  Recentes", ":Telescope oldfiles <CR>"),
        dashboard.button("q", "󰅙  Sair", ":qa <CR>"),
      }
      
      -- Cores do tema para o Dashboard
      vim.api.nvim_set_hl(0, "AlphaHeader", { fg = "#A6B1E1" })
      vim.api.nvim_set_hl(0, "AlphaButtons", { fg = "#DCD6F7" })
      
      dashboard.opts.opts.noautocmd = true
      alpha.setup(dashboard.opts)
    end
  }
})

-- --- ATALHOS BÁSICOS ---
-- Leader + w para salvar rápido
vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = 'Salvar arquivo' })
-- Leader + q para fechar rápido
vim.keymap.set('n', '<leader>q', ':q<CR>', { desc = 'Fechar arquivo' })
-- Tirar o destaque da busca com Leader + h
vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>', { desc = 'Tirar destaque da busca' })

-- --- ATALHOS DO TELESCOPE ---
-- Pcall para carregar as funções do telescope sem quebrar a inicialização inicial
local ok_builtin, builtin = pcall(require, 'telescope.builtin')
if ok_builtin then
  vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Localizar Arquivos' })
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Buscar Texto' })
  vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Listar Buffers' })
end

-- --- APLICAÇÃO DO TEMA ---
-- Tenta carregar o Catppuccin de forma segura (evita erros no primeiro boot enquanto instala)
local status_theme, _ = pcall(vim.cmd.colorscheme, "catppuccin")
if not status_theme then
  vim.cmd.colorscheme("default")
end
