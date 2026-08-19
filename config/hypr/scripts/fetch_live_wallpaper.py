import sys
import os
import re
import urllib.request
import urllib.parse
import random

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Safari/605.1.15"
]

def make_request(url):
    req = urllib.request.Request(url, headers={"User-Agent": random.choice(USER_AGENTS)})
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            return response.read().decode('utf-8', errors='ignore')
    except Exception as e:
        print(f"Error requesting {url}: {e}", file=sys.stderr)
        return None

def download_file(url, dest_path):
    req = urllib.request.Request(url, headers={"User-Agent": random.choice(USER_AGENTS)})
    try:
        with urllib.request.urlopen(req, timeout=15) as response, open(dest_path, 'wb') as out_file:
            out_file.write(response.read())
        return True
    except Exception as e:
        print(f"Error downloading {url}: {e}", file=sys.stderr)
        return False

def check_url_exists(url):
    req = urllib.request.Request(url, method='HEAD', headers={"User-Agent": random.choice(USER_AGENTS)})
    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            return response.status == 200
    except Exception:
        return False

def main():
    query = sys.argv[1] if len(sys.argv) > 1 else ""
    
    # 1. Search on MotionBGs
    if query:
        encoded_query = urllib.parse.quote(query)
        search_url = f"https://motionbgs.com/search?q={encoded_query}"
        html = make_request(search_url)
    else:
        # Fallback to the 4K wallpapers main list if no query
        search_url = "https://motionbgs.com/4k/"
        html = make_request(search_url)
        
    if not html:
        # Final fallback to home page
        search_url = "https://motionbgs.com"
        html = make_request(search_url)

    if not html:
        print("Error: Could not load MotionBGs", file=sys.stderr)
        sys.exit(1)

    # 2. Extract wallpaper slug URLs
    # Links are formatted as href=/oni-mask-girl, href=/digital-riot-girl etc.
    # Exclude system pages
    excluded_slugs = {'about', 'privacy', 'dmca', 'guides', 'contact', 'mobile', '4k', 'search'}
    
    slugs = []
    # Find all hrefs starting with '/' followed by word characters/dashes
    for match in re.finditer(r'href=/([a-zA-Z0-9\-]+)', html):
        slug = match.group(1)
        if slug not in excluded_slugs and slug not in slugs:
            slugs.append(slug)
            
    # If no slugs found on search, fallback to frontpage slugs
    if not slugs and query:
        print(f"No results for query '{query}', falling back to popular list...", file=sys.stderr)
        html = make_request("https://motionbgs.com")
        if html:
            for match in re.finditer(r'href=/([a-zA-Z0-9\-]+)', html):
                slug = match.group(1)
                if slug not in excluded_slugs and slug not in slugs:
                    slugs.append(slug)

    if not slugs:
        print("Error: No wallpaper links found", file=sys.stderr)
        sys.exit(1)

    # Choose a random wallpaper slug
    selected_slug = random.choice(slugs)
    wallpaper_page_url = f"https://motionbgs.com/{selected_slug}"
    print(f"Selected wallpaper page: {wallpaper_page_url}", file=sys.stderr)

    # 3. Fetch wallpaper page and extract mp4 link
    page_html = make_request(wallpaper_page_url)
    if not page_html:
        print("Error: Could not load wallpaper page", file=sys.stderr)
        sys.exit(1)

    # Find the contentUrl or any mp4 link
    # Standard: "contentUrl": "https://motionbgs.com/media/9382/cyberpunk-2077-night-city.960x540.mp4"
    mp4_matches = re.findall(r'(https?://[^\s\"\'\>]+?\.mp4)', page_html)
    if not mp4_matches:
        print("Error: No MP4 download link found on page", file=sys.stderr)
        sys.exit(1)

    base_mp4_url = mp4_matches[0]
    
    # By default, MotionBGs embeds a 960x540 preview video.
    # We want to upgrade it to 1080p (1920x1080) for native quality!
    hd_mp4_url = base_mp4_url.replace("960x540.mp4", "1920x1080.mp4")
    
    # Verify if 1080p exists, otherwise use the base preview URL
    if check_url_exists(hd_mp4_url):
        download_url = hd_mp4_url
        print("Upgraded video link to 1080p!", file=sys.stderr)
    else:
        download_url = base_mp4_url
        print("1080p version not found, downloading standard version.", file=sys.stderr)

    # 4. Download the video file
    dest_dir = "/home/eduardo/.config/hypr"
    dest_path = os.path.join(dest_dir, "current_wallpaper.mp4")
    
    print(f"Downloading video from {download_url}...", file=sys.stderr)
    if download_file(download_url, dest_path):
        # Print only the final file path to stdout for the bash script to consume
        print(dest_path)
    else:
        print("Error: Download failed", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
