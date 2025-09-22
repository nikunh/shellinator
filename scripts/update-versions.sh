#!/bin/bash
# Manual version update trigger script for Shellinator DevContainer features

set -e

REPO="nikunh/shellinator"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  feature <name> <version>  - Update specific feature to version"
    echo "  force-now                 - Force immediate batch update"
    echo "  list-pending              - Show pending updates"
    echo "  help                      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 feature ai-tools-vishkrm/ai-tools 0.0.11"
    echo "  $0 feature tmux-neovim-git-vishkrm/tmux-neovim-git 0.0.13"
    echo "  $0 force-now"
    echo ""
    echo "Note: Requires 'gh' CLI to be installed and authenticated"
}

check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI 'gh' is not installed${NC}"
        echo "Install it from: https://cli.github.com/"
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI is not authenticated${NC}"
        echo "Run: gh auth login"
        exit 1
    fi
}

trigger_feature_update() {
    local feature_name="$1"
    local version="$2"

    if [[ -z "$feature_name" || -z "$version" ]]; then
        echo -e "${RED}Error: Feature name and version are required${NC}"
        usage
        exit 1
    fi

    echo -e "${YELLOW}Triggering update for ${feature_name} → ${version}${NC}"

    gh api repos/$REPO/dispatches \
        --method POST \
        --field event_type="feature_version_update" \
        --field client_payload="{\"feature\":\"$feature_name\",\"version\":\"$version\",\"manual\":true,\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

    echo -e "${GREEN}✅ Update event sent successfully${NC}"
    echo "The batch update workflow will process this within 10 minutes, or you can force immediate processing with:"
    echo "  $0 force-now"
}

force_immediate_update() {
    echo -e "${YELLOW}Forcing immediate batch update...${NC}"

    gh api repos/$REPO/dispatches \
        --method POST \
        --field event_type="force_update_now" \
        --field client_payload="{\"manual\":true,\"force\":true,\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

    echo -e "${GREEN}✅ Immediate update triggered${NC}"
    echo "Check the workflow status at: https://github.com/$REPO/actions"
}

list_pending_updates() {
    echo -e "${YELLOW}Checking for pending updates...${NC}"

    # Try to read the pending updates file
    if gh api repos/$REPO/contents/.github/version-updates/pending.json 2>/dev/null | jq -r '.content' | base64 -d | grep -v "^$" | head -10; then
        echo -e "${YELLOW}Note: Showing last 10 pending updates${NC}"
    else
        echo -e "${GREEN}No pending updates found${NC}"
    fi
}

bulk_update_current_versions() {
    echo -e "${YELLOW}Updating all features to their current published versions...${NC}"

    # List of features to check and update
    features=(
        "ai-tools-vishkrm/ai-tools"
        "tmux-neovim-git-vishkrm/tmux-neovim-git"
        "babaji-config-vishkrm/babaji-config"
        "devops-tools-vishkrm/devops-tools"
        "003-zsh-setup-vishkrm/003-zsh-setup"
    )

    for feature in "${features[@]}"; do
        # Extract repo name from feature path
        repo_name="${feature%-vishkrm/*}-vishkrm"

        echo "Checking latest version for $feature..."

        # Get latest version from the feature's devcontainer-feature.json
        latest_version=$(gh api repos/nikunh/$repo_name/contents/src/${feature#*/}/devcontainer-feature.json | jq -r '.content' | base64 -d | jq -r '.version')

        if [[ "$latest_version" != "null" && -n "$latest_version" ]]; then
            echo "Found version $latest_version for $feature"
            trigger_feature_update "$feature" "$latest_version"
            sleep 1  # Small delay between API calls
        else
            echo -e "${RED}Could not determine latest version for $feature${NC}"
        fi
    done

    echo -e "${GREEN}✅ Bulk update requests sent${NC}"
    echo "Force immediate processing with: $0 force-now"
}

main() {
    check_gh_cli

    case "${1:-help}" in
        "feature")
            trigger_feature_update "$2" "$3"
            ;;
        "force-now")
            force_immediate_update
            ;;
        "list-pending")
            list_pending_updates
            ;;
        "bulk-current")
            bulk_update_current_versions
            ;;
        "help"|"")
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown command '$1'${NC}"
            echo ""
            usage
            exit 1
            ;;
    esac
}

main "$@"