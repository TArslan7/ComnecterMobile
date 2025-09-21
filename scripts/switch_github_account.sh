#!/bin/bash

# GitHub Account Switcher Script
# This script allows you to quickly switch between different GitHub accounts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show current account
show_current_account() {
    echo -e "${BLUE}Current Git Configuration:${NC}"
    echo -e "Name: ${GREEN}$(git config --global user.name)${NC}"
    echo -e "Email: ${GREEN}$(git config --global user.email)${NC}"
    echo ""
}

# Function to list available accounts
list_accounts() {
    echo -e "${BLUE}Available GitHub Accounts:${NC}"
    echo "1) TArslan7 (T_Arslan7@hotmail.com) - Current"
    echo "2) [Add your other account here]"
    echo ""
}

# Function to switch to account 1 (TArslan7)
switch_to_account1() {
    echo -e "${YELLOW}Switching to TArslan7 account...${NC}"
    git config --global user.name "TArslan7"
    git config --global user.email "T_Arslan7@hotmail.com"
    echo -e "${GREEN}Successfully switched to TArslan7 account!${NC}"
    show_current_account
}

# Function to switch to account 2 (placeholder)
switch_to_account2() {
    echo -e "${YELLOW}Switching to Account 2...${NC}"
    echo -e "${RED}Please configure your second account details first!${NC}"
    echo ""
    echo "To add your second account, edit this script and update the details."
    echo "Or run: git config --global user.name 'YourName' && git config --global user.email 'your.email@example.com'"
}

# Function to add new account
add_new_account() {
    echo -e "${BLUE}Adding new GitHub account...${NC}"
    read -p "Enter account name: " account_name
    read -p "Enter account email: " account_email
    
    echo ""
    echo -e "${YELLOW}Switching to new account: $account_name ($account_email)${NC}"
    git config --global user.name "$account_name"
    git config --global user.email "$account_email"
    echo -e "${GREEN}Successfully switched to new account!${NC}"
    show_current_account
}

# Function to show help
show_help() {
    echo -e "${BLUE}GitHub Account Switcher - Usage:${NC}"
    echo ""
    echo "Commands:"
    echo "  current    - Show current account configuration"
    echo "  list       - List available accounts"
    echo "  switch1    - Switch to TArslan7 account"
    echo "  switch2    - Switch to Account 2 (if configured)"
    echo "  add        - Add and switch to a new account"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./switch_github_account.sh current"
    echo "  ./switch_github_account.sh switch1"
    echo "  ./switch_github_account.sh add"
    echo ""
}

# Main script logic
case "${1:-help}" in
    "current")
        show_current_account
        ;;
    "list")
        list_accounts
        ;;
    "switch1")
        switch_to_account1
        ;;
    "switch2")
        switch_to_account2
        ;;
    "add")
        add_new_account
        ;;
    "help"|*)
        show_help
        ;;
esac

