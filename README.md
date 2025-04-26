# 📚 eClass Downloader Script

A simple Bash script that automates the downloading of course materials from the [eClass platform](https://eclass.upatras.gr), widely used by Greek universities.

## 🚀 Features

- 📦 Download all materials using the "Download all as ZIP" button (when available)
- 🧭 Automatically crawl and download every individual file if ZIP is not provided
- 🔐 Supports authenticated downloads via user session cookies

## 🛠️ Usage

```bash
./grab_files.sh <eclass_course_url> <mode> <cookies_file>
```

### Arguments:

First Argument (eclass_course_url) is mandatory
Second argument (destination_dir) is optional and defaults to the current directory (where the script is run from)
Third argument (mode) is optional and defaults to 0
Fourth argument (cookies file) is optional, but if you don't provide one, then you should append your session cookies to a file cookies.txt in the current directory (which is the default file location)

| Argument               | Description                                                                             |
|------------------------|-----------------------------------------------------------------------------------------|
| `<eclass_course_url>`  | Full URL of the course's main eClass page (e.g. https://eclass.tuc.gr/courses/ABC123/)  |
| `<destination_dir>`    | Destination folder for the extracted/downloaded files                                   |
| `<mode>`               | `0` = use ZIP button if available; `1` = crawl and download all files individually      |
| `<cookies_file>`       | File containing your authenticated session cookies                                      |

---

## 🍪 How to get your eClass cookies

You need to export your browser session cookies so the script can authenticate and download the materials.

### ✅ Option 1: Use your browser's DevTools

1. Go to the eClass course page and make sure you're logged in.
2. Open Developer Tools (press Ctrl + Shift + I or Ctrl + F12).
3. Click on the Application tab.
4. In the left sidebar, under Storage → Cookies, select the eClass site (e.g., https://eclass.tuc.gr).
5. Look for the cookie named PHPSESSID in the list.
6. Copy its Name=Value pair (e.g., PHPSESSID=abc123xyz456).
7. Paste this into a plain text file called cookies.txt.
8. Paste it into a file, e.g. `cookies.txt`

   Your cookie file should look like:
   ```
   eclass.uniwa.gr        TRUE    /       FALSE   0       PHPSESSID       lhr1oqs6nbg09qrerfbm4akqin
   ```

### ✅ Option 2: Use a browser extension

- [EditThisCookie (Chrome)](https://chrome.google.com/webstore/detail/editthiscookie/fngmhnnpilhplaeedifhccceomclgfbg)
- [Cookie-Editor (Firefox/Chrome)](https://www.cookie-editor.com/)

Use the extension to export your cookies as plain text and save them to `cookies.txt`.

---

## 📦 Examples

### 🔹 Example 1: Using the ZIP button (mode 0)

```bash
./grab_files.sh "https://eclass.tuc.gr/courses/ABC123/" 0 cookies.txt
```

This will download the ZIP file (if the button exists) and extract it.

### 🔹 Example 2: Crawling and downloading each file (mode 1)

```bash
./grab_files.sh "https://eclass.tuc.gr/courses/ABC123/" 1 my_cookies.txt
```

This will crawl through the course page and download each file individually.

---

## 🧾 Notes

- This script assumes basic familiarity with bash, wget or curl.
- Always respect your institution’s policies for automation and access.

---

## 📜 License

MIT – do whatever you want with it, just don’t blame me if eClass changes everything overnight 😅
