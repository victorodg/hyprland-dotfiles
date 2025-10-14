#!/bin/bash

# --- VARIÁVEIS DE CONFIGURAÇÃO ---
SOURCE_DIR="$HOME/.config"
DEST_DIR="$HOME/Documents/hyprland"
COMMIT_MSG="Auto-sync: $(date --iso-8601=seconds)"

CONFIG_FOLDERS=(
    "hypr"
    "hyprpaper"
    "kitty"
    "waybar"
    "wofi"
)

# --- ETAPA 1: SINCRONIZAÇÃO LOCAL ---
echo "Starting configuration sync..."
for folder in "${CONFIG_FOLDERS[@]}"; do
    if [ -d "$SOURCE_DIR/$folder" ]; then
        rsync -a --delete "$SOURCE_DIR/$folder/" "$DEST_DIR/$folder/"
    fi
done
echo "Local sync complete."

# --- ETAPA 2: COMMIT E PUSH PARA O GITHUB ---
echo "Pushing changes to GitHub..."

# Entra no diretório do repositório Git
cd "$DEST_DIR" || exit

# Verifica se há alterações para commitar
if [ -n "$(git status --porcelain)" ]; then
    # Adiciona todos os arquivos novos, modificados ou deletados
    git add .

    # Cria o commit com uma mensagem dinâmica
    git commit -m "$COMMIT_MSG"

    # Faz o push para o GitHub
    git push origin main

    echo "Push to GitHub complete."
else
    echo "No changes to commit. Nothing to do."
fi

exit 0