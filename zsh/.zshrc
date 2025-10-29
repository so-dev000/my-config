alias python='python3'
source ~/.zsh/git-prompt.sh

GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUPSTREAM=auto

setopt PROMPT_SUBST ; PS1='%F{green}%n@%m%f: %F{cyan}%~%f %F{red}$(__git_ps1 "(%s)")%f$ '
eval "$(direnv hook zsh)"

alias ojt='oj t -c "python main.py" -d test'
alias accs='acc s -- main.py --language 5078'
eval "$(rbenv init -)"
export PATH="$HOME/.gem/ruby/*/bin:$PATH"
eval `opam config env`

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

alias miniml='cat | dune exec miniml'

alias gemini='gemini --checkpointing'
alias gemini-flash='gemini --checkpointing -m gemini-2.5-flash' 


export SUPPRESS_CRASH_REPORT=1

alias rails-s='rails assets:clobber && rails assets:precompile && rails s'


if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

    autoload -Uz compinit
    compinit
fi


source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

eval "$(direnv hook zsh)"

# ============================================
# Git AI Review Aliases
# ============================================
alias git-review='~/.git-hooks/ai-review.sh'
alias git-review-status='~/.git-hooks/review-status.sh'

# Add ~/bin to PATH for custom git commands
export PATH="$HOME/bin:$PATH"

# Created by `pipx` on 2025-10-17 14:41:23
export PATH="$PATH:$HOME/.local/bin"

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

alias mkpyrightconf='printf "{\n  \"diagnosticMode\": \"off\",\n  \"typeCheckingMode\": \"off\"\n}\n" > pyrightconfig.json'