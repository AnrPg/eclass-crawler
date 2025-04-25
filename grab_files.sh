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

    echo -e "Downloading from $full_url\n"
    my_unzipped_folder="$destination_dir/catalog_$(date +%Y_%m_%d___%H_%M_%S)"
    mkdir -p $my_unzipped_folder && curl -i -L -b $cookies_file -o temp.zip "$full_url" && unzip -q temp.zip -d $my_unzipped_folder
    mapfile -t urls < <(unzip -Z1 temp.zip)
    rm temp.zip
    
    # exit 0
else
    mapfile -t urls < <(grep -oP "href=['\"]\K[^'\"]+\.(pdf|zip|rar|tar|gz|docx?|xlsx?|pptx?|txt|csv|7z|tar\.gz|tgz|mp4|mp3)" $destination_dir/page_to_grab.html)
fi

total=${#urls[@]}
if [ "${autograb_links:-0}" -eq 0 ]; then
    echo -e "\n🔍 Parent directory contains in total $total file(s):\n"
    zipped_files_count=$(find "$my_unzipped_folder" -maxdepth 1 -type f \( -iname "*.zip" -o -iname "*.rar" \) | wc -l)
    [ $zipped_files_count -ne 0 ] && echo -e "(of which, $zipped_files_count are compressed/packed (i.e. zip/rar/tar/7z/gz/tgz files) and can be further extracted)\n\n"
    printf '%s\n' "${urls[@]}"
else
    echo -e "\n🔍 Found $total downloadable file(s):\n"
    printf '%s\n' "${urls[@]}"
fi

# Progress tracking
count=0
downloaded=0
bar_length=50

for url in "${urls[@]}"; do
    ((count++))

    if [ "${autograb_links:-0}" -eq 0 ]; then
       
        # TODO: remove initial, un-decompressed files after decompression is finished
        
        ext="${url##*.}"  # Get the extension
        case "$ext" in
            zip)
            # echo "Unzipping: $url"
            unzip -o "$my_unzipped_folder/$url" -d "$my_unzipped_folder/"
            ;;
            rar)
            echo "Unpacking RAR: $url at $(dirname "$url")"
            unrar x -o+ "$my_unzipped_folder/$url" "$my_unzipped_folder/"
            ;;
            tar)
            # echo "Extracting tar: $url"
            tar -xf "$my_unzipped_folder/$url" -C "$my_unzipped_folder/"
            ;;
            # 7z)
            # # echo "Unpacking 7z: $url"
            # 7z x "$url" -o"$(dirname "$url")" -y
            # ;;
            # gz)
            # # echo "Decompressing gzip: $url"
            # gunzip -k "$url"  # -k keeps original .gz file
            # ;;
            # tgz|tar.gz)
            # # echo "Extracting tar.gz: $url"
            # tar -xzf "$url" -C "$(dirname "$url")"
            # ;;
            # *)
            # # echo "Skipping unsupported file: $url"
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

    # TODO: Fix progress bar -> 1) show percentage and summary correctly, 2) show loading animation correctly

    # Progress bar
    percent=$(( count * 100 / $total ))
    filled=$(( percent * bar_length / 100 ))
    bar=$(printf "%-${bar_length}s" "#" | cut -c1-$filled)
    printf "\r⬇️ Downloading: [%-${bar_length}s] %3d%% (%d/%d)" "$bar" "$percent" "$count" "$total"
done

echo -e "\n\n✅ Finished. Downloaded $downloaded new file(s)."
echo "📓 Progress log saved to: $log_file"
