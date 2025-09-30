# Shellinator DevPod Environment

A comprehensive DevContainer environment with custom features for development work.

## Features

This DevContainer includes:
- Custom babaji user setup with zsh and Oh My Zsh
- Development tools and utilities
- AI development tools (aider, tmux-neovim with AI integration)
- Cloud and DevOps tools
- Python/Conda environment
- Node.js and Go development environments
- Kubernetes tools
- And much more!

## Usage with DevPod

```bash
# Create and start the environment
devpod up https://github.com/nikunh/shellinator

# SSH into the environment
ssh shellinator.devpod
```

## SSH Access

The environment includes SSH server configuration and runs as the `babaji` user with full zsh and development environment setup.
