#!/bin/bash

website="$1"
destination_dir="${2:-.}"
autograb_links="${3:-1}" # If arg 3 is missing, set it to default (to automatically crawl the webpage, create a list of downloadable files and then grab them)
cookies_file="${4:-cookies.txt}"
log_file="$destination_dir/downloaded.log"

echo -e "\n🚀 Starting download script...\n"

# Create log file if it doesn't exist
touch "$log_file"

# Fetch the page
curl -s -b $cookies_file -L -o $destination_dir/page_to_grab.html "$website"


# Extract file links
if [ "${autograb_links:-0}" -eq 0 ]; then
    echo -e "\nDownloading files using the button for batch downloading the parent folder...\n"
    url=$(grep -oP "<a\s+href=['\"]\K[^'\"]+(?=['\"][^>]*>\s*<span[^>]*title=['\"]Λήψη όλου του καταλόγου)" $destination_dir/page_to_grab.html | sed 's/&amp;/\&/g')
    
    if [[ "$full_url" != http* ]]; then
        base=$(echo "$website" | sed 's|\(https*://[^/]*\).*|\1|')
        full_url="${base}${url}"
    else
        full_url="$url"
    fi

    my_unzipped_folder="$destination_dir/catalog_$(date +%Y_%m_%d___%H_%M_%S)"
    mkdir -p $my_unzipped_folder && curl -i -L -b $cookies_file -o temp.zip "$full_url" && unzip -q temp.zip -d $my_unzipped_folder
    mapfile -t urls < <(unzip -Z1 temp.zip)
    rm temp.zip
    zipped_files_count=$(find "$my_unzipped_folder" -maxdepth 1 -type f \( -iname "*.zip" -o -iname "*.rar" \) | wc -l)
    exit 0
else
    mapfile -t urls < <(grep -oP "href=['\"]\K[^'\"]+\.(pdf|zip|rar|tar|gz|docx?|xlsx?|pptx?|txt|csv|7z|tar\.gz|tgz|mp4|mp3)" $destination_dir/page_to_grab.html)
fi

total=${#urls[@]}
echo "🔍 Found $total downloadable file(s):"
printf '%s\n' "${urls[@]}"

# Progress tracking
count=${zipped_files_count:-0}
downloaded=0
bar_length=50

for url in "${urls[@]}"; do
    ((count++))

    if [ "${autograb_links:-0}" -eq 0 ]; then
       
        ext="${url##*.}"  # Get the extension
        case "$ext" in
            zip)
            # echo "Unzipping: $file"
            unzip -o "$file" -d "$(dirname "$file")"
            ;;
            rar)
            echo "Unpacking RAR: $file at $(dirname "$file")"
            unrar x -o+ "$file" "$(dirname "$file")/"
            ;;
            tar)
            # echo "Extracting tar: $file"
            tar -xf "$file" -C "$(dirname "$file")"
            ;;
            # 7z)
            # # echo "Unpacking 7z: $file"
            # 7z x "$file" -o"$(dirname "$file")" -y
            # ;;
            # gz)
            # # echo "Decompressing gzip: $file"
            # gunzip -k "$file"  # -k keeps original .gz file
            # ;;
            # tgz|tar.gz)
            # # echo "Extracting tar.gz: $file"
            # tar -xzf "$file" -C "$(dirname "$file")"
            # ;;
            # *)
            # # echo "Skipping unsupported file: $file"
            # ;;
        esac
    else        
         # Handle relative URLs
        if [[ "$url" != http* ]]; then
            base=$(echo "$website" | sed 's|\(https*://[^/]*\).*|\1|')
            full_url="${base}/${url}"
        else
            full_url="$url"
        fi

        # Check if already downloaded
        if grep -Fxq "$full_url" "$log_file"; then
            percent=$(( count * 100 / total ))
            filled=$(( percent * bar_length / 100 ))
            bar=$(printf "%-${bar_length}s" "#" | cut -c1-$filled)
            printf "\rSkipping (already in log): [%-${bar_length}s] %3d%% (%d/%d)" "$bar" "$percent" "$count" "$total"
            continue
        fi

        # Download
        if curl -s -b $cookies_file -L -O "$full_url"; then # TODO: check that output is saved in the dir specified by the argument
            echo "$full_url" >> "$log_file"
            ((downloaded++))
        fi
    fi

    # Progress bar
    percent=$(( count * 100 / total ))
    filled=$(( percent * bar_length / 100 ))
    bar=$(printf "%-${bar_length}s" "#" | cut -c1-$filled)
    printf "\r⬇️ Downloading: [%-${bar_length}s] %3d%% (%d/%d)" "$bar" "$percent" "$count" "$total"
done

echo -e "\n\n✅ Finished. Downloaded $downloaded new file(s)."
echo "📓 Progress log saved to: $log_file"
