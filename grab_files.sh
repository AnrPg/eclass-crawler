#!/bin/bash

# TODO: refactor code to avoid code repetitions for the two modes. Also give better names to urls, url, downloaded

# TODO: check for available free space before extracting

set -uo pipefail

website="$1"
destination_dir="${2:-$PWD}"
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
    
    if [[ "$url" != http* ]]; then
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

orig_dir="$PWD"

# Loop through urls and download or unpack them depending on the mode
# If mode = 1 then download all links in the page, one by one, while
# if mode = 0, that means that you downloaded a zip with all files, so
# now you have to decompress any file that is compressed
for url in "${urls[@]}"; do
    ((count++))

    if [ "${autograb_links:-0}" -eq 0 ]; then
               
        ext="${url##*.}"  # Get the extension
        case "$ext" in
            zip)
            echo -e "\nUnzipping: $url"
            unzip -o "$my_unzipped_folder/$url" -d "$my_unzipped_folder/"
            rm "$my_unzipped_folder/$url"
            ;;
            rar)
            echo -e "\nUnpacking RAR: $url at $(dirname "$url")"
            unrar x -o+ "$my_unzipped_folder/$url" "$my_unzipped_folder/"
            rm "$my_unzipped_folder/$url"
            ;;
            tar)
            echo -e "\nExtracting tar: $url"
            tar -xf "$my_unzipped_folder/$url" -C "$my_unzipped_folder/"
            rm "$my_unzipped_folder/$url"
            ;;
            7z)
            echo -e "\nUnpacking 7z: $url"
            7z x "$url" -o"$(dirname "$url")" -y
            rm "$my_unzipped_folder/$url"
            ;;
            gz)
            echo -e "\nDecompressing gzip: $url"
            gunzip -k "$url"  # -k keeps original .gz file
            rm "$my_unzipped_folder/$url"
            ;;
            tgz|tar.gz)
            echo -e "\nExtracting tar.gz: $url"
            tar -xzf "$url" -C "$(dirname "$url")"
            rm "$my_unzipped_folder/$url"
            ;;
            *)
            echo -e "\nSkipping unsupported file: $url"
            ;;
        esac
        ((downloaded++))
    else        
        #  Handle relative URLs
        if [[ "$url" != http* ]]; then
            base=$(echo "$website" | sed 's|\(https*://[^/]*\).*|\1|')
            full_url="${base}/${url}"
        else
            full_url="$url"
        fi

        # Check if already downloaded
        echo -e "\nChecking if file is already downloaded\n"
        if grep -Fxq "$full_url" "$log_file"; then
            percent=$(( count * 100 / total ))
            filled=$(( percent * bar_length / 100 ))
            bar=$(printf "%-${bar_length}s" "#" | cut -c1-$filled)
            printf "\rSkipping (already in log): [%-${bar_length}s] %3d%% (%d/%d)" "$bar" "$percent" "$count" "$total"
            continue
        fi

        # Download
        cd $destination_dir # TODO: move it out of the loop (taking into consideration the case where mode=0)
        if filename=$(curl -s -b $cookies_file --write-out "%{filename_effective}" -L -OJ "$full_url"); then 
            # echo -e "\n--------------\n\norig_dir: $orig_dir\n\ndestination_dir: $destination_dir\n\ncurrent_dir: $PWD\n\n---------------\n\n"
            echo "$full_url" >> "$log_file"
            ((downloaded++))
            # ext="${filename##*.}"  # Get the extension
            # # echo -e "\n--------------\n\norig_dir: $orig_dir\n\ndestination_dir: $destination_dir\n\nfilename: $filename\n\nfull_url: $full_url\n\next: $ext\n\n---------------\n\n"
            # case "$ext" in
            #     zip)
            #     echo -e "\nUnzipping: $filename at $destination_dir/$filename"
            #     unzip -o "$destination_dir/$filename" -d "$destination_dir/"
            #     rm "$destination_dir/$filename"
            #     ;;
            #     rar)
            #     echo -e "\nUnpacking RAR: $filename at $destination_dir/$filename"
            #     unrar x -o+ "$destination_dir/$filename" "$destination_dir/"
            #     # rm "$destination_dir/$filename"
            #     ;;
            #     tar)
            #     echo -e "\nExtracting tar: $filename at $destination_dir/$filename"
            #     tar -xf "$destination_dir/$filename" -C "$destination_dir/"
            #     rm "$destination_dir/$filename"
            #     ;;
            #     7z)
            #     echo -e "\nUnpacking 7z: $filename at $destination_dir/$filename"
            #     7z x "$filename" -o"$(dirname "$filename")" -y
            #     rm "$destination_dir/$filename"
            #     ;;
            #     gz)
            #     echo -e "\nDecompressing gzip: $filename at $destination_dir/$filename"
            #     gunzip -k "$filename"  # -k keeps original .gz file
            #     rm "$destination_dir/$filename"
            #     ;;
            #     tgz|tar.gz)
            #     echo -e "\nExtracting tar.gz: $filename at $destination_dir/$filename"
            #     tar -xzf "$filename" -C "$(dirname "$filename")"
            #     rm "$destination_dir/$filename"
            #     ;;
            #     *)
            #     echo -e "\nSkipping unsupported file: $filename"
            #     ;;
            # esac
        fi
    fi

    # TODO: Fix progress bar -> 1) show percentage and summary correctly, 2) show loading animation correctly

    # Progress bar
    percent=$(( count * 100 / $total ))
    filled=$(( percent * bar_length / 100 ))
    bar=$(printf "%-${bar_length}s" "#" | cut -c1-$filled)
    printf "\r⬇️ Downloading: [%-${bar_length}s] %3d%% (%d/%d)" "$bar" "$percent" "$count" "$total"
done

cd $orig_dir

echo -e "\n\n✅ Finished. Downloaded $downloaded new file(s)."
echo "📓 Progress log saved to: $log_file"