import os
import urllib.request
import zipfile
import shutil

def main():
    url = "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse?project=jdk"
    zip_path = "jdk17.zip"
    extract_dir = "jdk17"
    
    print(f"Downloading JDK 17 from: {url}")
    # Using a browser User-Agent to avoid blocking
    req = urllib.request.Request(
        url, 
        headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
    )
    
    with urllib.request.urlopen(req) as response, open(zip_path, 'wb') as out_file:
        shutil.copyfileobj(response, out_file)
        
    print("Download completed! Extracting...")
    
    if os.path.exists(extract_dir):
        try:
            shutil.rmtree(extract_dir)
        except Exception as e:
            print("Warning: could not clean extract_dir:", e)
        
    os.makedirs(extract_dir, exist_ok=True)
    
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_dir)
        
    print("Extraction complete!")
    
    # Clean up the zip file
    if os.path.exists(zip_path):
        os.remove(zip_path)
        
    # Find the bin/java.exe path in the extracted folder
    java_exe = None
    for root, dirs, files in os.walk(extract_dir):
        if "java.exe" in files:
            java_exe = os.path.join(root, "java.exe")
            break
            
    if java_exe:
        print(f"Java executable found at: {java_exe}")
        # The parent of the 'bin' folder is our JAVA_HOME
        java_home = os.path.abspath(os.path.dirname(os.path.dirname(java_exe)))
        print(f"JAVA_HOME should be: {java_home}")
    else:
        print("Error: java.exe not found in extracted files.")

if __name__ == "__main__":
    main()
