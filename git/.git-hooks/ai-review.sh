#!/bin/bash
# AI Code Review Engine - Minimal Output

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Paths
readonly HOOKS_DIR="$HOME/.git-hooks"
readonly MODEL="claude-sonnet-4-5-20250929"

# Spinner function
show_spinner() {
    local pid=$1
    local message=$2
    local spinstr='|/-\'
    local temp

    printf "\n"
    while kill -0 "$pid" 2>/dev/null; do
        temp=${spinstr#?}
        printf "\r${YELLOW}[%c]${NC} ${BOLD}%s${NC}" "$spinstr" "$message"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.15
    done
    printf "\r%*s\r" $((${#message} + 13)) ""
}

# Colorize review output
colorize_review() {
    while IFS= read -r line; do
        # Section titles (【】)
        if [[ "$line" =~ ^【.*】$ ]]; then
            echo -e "${CYAN}${BOLD}$line${NC}"
        # Issue severity markers
        elif [[ "$line" =~ ^-\ \[重大\]\ (.*)$ ]]; then
            echo -e "- ${RED}${BOLD}[重大]${NC} ${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^\[重大\]\ (.*)$ ]]; then
            echo -e "${RED}${BOLD}[重大]${NC} ${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^-\ \[警告\]\ (.*)$ ]]; then
            echo -e "- ${YELLOW}${BOLD}[警告]${NC} ${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^\[警告\]\ (.*)$ ]]; then
            echo -e "${YELLOW}${BOLD}[警告]${NC} ${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^-\ \[提案\]\ (.*)$ ]]; then
            echo -e "- ${BLUE}${BOLD}[提案]${NC} ${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^\[提案\]\ (.*)$ ]]; then
            echo -e "${BLUE}${BOLD}[提案]${NC} ${BASH_REMATCH[1]}"
        # Review-Result line
        elif [[ "$line" =~ ^Review-Result:\ OK$ ]]; then
            echo -e "${GREEN}${BOLD}$line${NC}"
        elif [[ "$line" =~ ^Review-Result:\ NG$ ]]; then
            echo -e "${RED}${BOLD}$line${NC}"
        elif [[ "$line" =~ ^Review-Result: ]]; then
            echo -e "${BOLD}$line${NC}"
        else
            echo "$line"
        fi
    done
}

# Run review
run_review() {
    local diff_content="$1"
    local temp_input=$(mktemp)
    local temp_output=$(mktemp)
    local prompt_file="$HOOKS_DIR/review-prompt.txt"

    if [ ! -f "$prompt_file" ]; then
        echo -e "${RED}✗ Review prompt not found:${NC} $prompt_file"
        rm -f "$temp_input" "$temp_output"
        return 1
    fi

    cat "$prompt_file" > "$temp_input"
    echo "" >> "$temp_input"
    echo "$diff_content" >> "$temp_input"

    local error_output
    if error_output=$(claude --model "$MODEL" < "$temp_input" 2>&1 > "$temp_output"); then
        cat "$temp_output" | colorize_review
        local exit_code=0
    else
        echo -e "${RED}✗ Review failed${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}Claude CLI Error:${NC}"
        echo "$error_output"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        local exit_code=1
    fi

    rm -f "$temp_input" "$temp_output"
    return $exit_code
}

# Main
main() {
    if ! command -v claude >/dev/null 2>&1; then
        echo -e "${RED}✗ Claude CLI not found${NC}"
        echo -e "  Please install the Claude CLI to enable AI code review."
        exit 1
    fi

    local staged_files=$(git diff --cached --name-only --diff-filter=ACM)
    if [ -z "$staged_files" ]; then
        echo -e "${YELLOW}⚠ No files staged for commit${NC}"
        exit 0
    fi

    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  AI Code Review${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}Changes to be reviewed:${NC}"
    echo ""
    git diff --cached --stat --color=always
    echo ""

    local diff_content=$(git diff --cached)
    if [ -z "$diff_content" ]; then
        echo -e "${YELLOW}⚠ No changes detected${NC}"
        exit 0
    fi

    # Run review with spinner
    local temp_result=$(mktemp)
    (run_review "$diff_content" > "$temp_result"; echo $? > "$temp_result.exit") &
    local review_pid=$!

    show_spinner $review_pid "Analyzing changes..."

    wait $review_pid
    local review_exit_code=$(cat "$temp_result.exit")

    # Display result
    cat "$temp_result"
    echo ""

    # Check review result
    if grep -qi "Review-Result: NG" "$temp_result"; then
        rm -f "$temp_result" "$temp_result.exit"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}✗ Issues found during AI review${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        return 1
    else
        rm -f "$temp_result" "$temp_result.exit"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✓ Review completed successfully${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        return 0
    fi
}

if main "$@"; then
    exit 0
else
    exit 1
fi
