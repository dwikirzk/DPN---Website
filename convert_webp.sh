#!/bin/bash

# ======================================================
# Script konversi gambar ke WebP dengan ImageMagick
# Didesain untuk folder DPN/assets/image
# ======================================================

# Warna untuk output di terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Konfigurasi Default ---
QUALITY=75                    # Kualitas WebP (0-100). Nilai 75 adalah default ImageMagick.
TARGET_DIR="./assets/image"   # Folder target tempat gambar berada.
METHOD=6                      # Metode kompresi (0-6). 6 = kualitas terbaik (paling lambat).
BACKUP_DIR="./backup_images"  # Lokasi folder backup.
DELETE_ORIGINAL=true          # Hapus file asli (png, jpg, dll) setelah berhasil dikonversi.
CREATE_BACKUP=false           # Buat salinan cadangan file asli sebelum dikonversi.

# --- Fungsi untuk Menampilkan Panduan Penggunaan ---
usage() {
    echo "Penggunaan: $0 [options]"
    echo "Options:"
    echo "  -d, --dir DIR       Tentukan folder target gambar (default: ./assets/image)"
    echo "  -q, --quality NUM   Atur kualitas WebP 0-100 (default: 75)"
    echo "  -m, --method NUM    Atur metode kompresi 0-6 (default: 6 untuk ukuran file terkecil)"
    echo "  -b, --backup        Buat backup file asli ke folder backup_images"
    echo "  -k, --keep          Jangan hapus file asli setelah konversi"
    echo "  -h, --help          Tampilkan panduan ini"
    exit 0
}

# --- Parsing Argumen dari Command Line ---
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        -q|--quality)
            QUALITY="$2"
            shift 2
            ;;
        -m|--method)
            METHOD="$2"
            shift 2
            ;;
        -b|--backup)
            CREATE_BACKUP=true
            shift
            ;;
        -k|--keep)
            DELETE_ORIGINAL=false
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Opsi '$1' tidak dikenal.${NC}"
            usage
            ;;
    esac
done

# --- Pengecekan Awal ---
# 1. Apakah direktori target ada?
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Direktori target '$TARGET_DIR' tidak ditemukan!${NC}"
    echo "Pastikan script dijalankan dari root proyek DPN, atau gunakan opsi '-d' untuk menentukan folder yang benar."
    exit 1
fi

# 2. Apakah perintah 'convert' dari ImageMagick tersedia dan mendukung WebP?
if ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: Perintah 'convert' dari ImageMagick tidak ditemukan.${NC}"
    echo "Pastikan ImageMagick sudah terinstal. Kunjungi https://imagemagick.org untuk panduan instalasi."
    exit 1
fi

# Verifikasi dukungan WebP
if ! convert -list format | grep -q "WEBP"; then
    echo -e "${RED}Error: Instalasi ImageMagick kamu tidak mendukung format WebP.${NC}"
    echo "Silakan instal library 'libwebp' terlebih dahulu."
    echo "Ubuntu/Debian: sudo apt install libwebp-dev"
    echo "macOS: brew install webp"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🖼️  Konversi Gambar ke WebP dengan ImageMagick${NC}"
echo -e "${GREEN}   Kualitas: $QUALITY, Metode: $METHOD${NC}"
echo -e "${GREEN}📁 Direktori target: $TARGET_DIR${NC}"
echo -e "${GREEN}========================================${NC}"

# --- Persiapan Backup (Opsional) ---
if [ "$CREATE_BACKUP" = true ]; then
    mkdir -p "$BACKUP_DIR"
    echo -e "${YELLOW}📦 Backup akan disimpan di $BACKUP_DIR${NC}"
fi

# --- Membuat File Sementara untuk Menyimpan Counter (Workaround untuk loop di subshell) ---
counter_file=$(mktemp)
echo "0 0 0" > "$counter_file"

# --- Proses Semua File Gambar ---
# Mencari file dengan ekstensi gambar yang umum (case-insensitive)
find "$TARGET_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \) -print0 | while IFS= read -r -d '' img; do
    
    # Update counter
    read TOTAL CONVERTED FAILED < "$counter_file"
    TOTAL=$((TOTAL + 1))

    filename=$(basename "$img")
    dirpath=$(dirname "$img")
    name_no_ext="${filename%.*}"
    output_file="$dirpath/${name_no_ext}.webp"

    # --- Backup Opsional ---
    if [ "$CREATE_BACKUP" = true ]; then
        backup_path="$BACKUP_DIR/${filename}"
        cp "$img" "$backup_path" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  ✅ Backup: $filename -> $BACKUP_DIR/${filename}${NC}"
        else
            echo -e "${RED}  ❌ Gagal backup $filename${NC}"
        fi
    fi

    # --- Konversi ke WebP dengan ImageMagick ---
    echo -n "  🔄 Mengonversi $filename ... "
    # Perintah convert: -strip untuk hapus metadata, -quality, -define webp:method
    convert "$img" -strip -quality "$QUALITY" -define webp:method="$METHOD" "$output_file"

    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        # Hitung rasio kompresi
        size_original=$(stat -c%s "$img" 2>/dev/null || stat -f%z "$img" 2>/dev/null)
        size_webp=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file" 2>/dev/null)
        if [ -n "$size_original" ] && [ -n "$size_webp" ] && [ $size_original -gt 0 ]; then
            ratio=$((100 * size_webp / size_original))
            echo -e "${GREEN}✅ BERHASIL${NC} (${ratio}% dari ukuran asli)"
        else
            echo -e "${GREEN}✅ BERHASIL${NC}"
        fi

        # Hapus file asli jika opsi aktif
        if [ "$DELETE_ORIGINAL" = true ]; then
            rm "$img"
            echo "       📄 File asli dihapus."
        fi
        
        CONVERTED=$((CONVERTED + 1))
    else
        echo -e "${RED}❌ GAGAL${NC}"
        FAILED=$((FAILED + 1))
    fi

    # Simpan counter terbaru
    echo "$TOTAL $CONVERTED $FAILED" > "$counter_file"
done

# --- Tampilkan Ringkasan ---
read TOTAL CONVERTED FAILED < "$counter_file"
rm "$counter_file"

echo -e "${GREEN}========================================${NC}"
echo -e "📊 RINGKASAN:"
echo -e "   Total gambar ditemukan : $TOTAL"
echo -e "   ${GREEN}Berhasil dikonversi   : $CONVERTED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "   ${RED}Gagal dikonversi      : $FAILED${NC}"
fi
echo -e "${GREEN}========================================${NC}"

if [ "$DELETE_ORIGINAL" = true ]; then
    echo -e "${YELLOW}⚠️  Catatan: File asli (PNG/JPG/dll) telah dihapus. Hanya file .webp yang tersisa.${NC}"
else
    echo -e "${YELLOW}⚠️  Catatan: File asli masih disimpan. Hapus manual jika sudah yakin dengan hasil konversi.${NC}"
fi

if [ "$CREATE_BACKUP" = true ]; then
    echo -e "${YELLOW}📦 Backup disimpan di folder $BACKUP_DIR. Hapus folder ini jika sudah tidak diperlukan.${NC}"
fi