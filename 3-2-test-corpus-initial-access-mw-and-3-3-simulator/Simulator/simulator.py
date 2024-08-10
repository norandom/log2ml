import os
import sys
import time
import pyautogui
import win32gui
import win32con

def close_cmd_window():
    def enum_windows_callback(hwnd, result):
        window_title = win32gui.GetWindowText(hwnd).lower()
        if (win32gui.IsWindowVisible(hwnd) and 
            'cmd.exe' in window_title and 
            'Anaconda' not in window_title):
            win32gui.PostMessage(hwnd, win32con.WM_CLOSE, 0, 0)
    
    win32gui.EnumWindows(enum_windows_callback, None)

def close_excel_without_saving():
    pyautogui.hotkey('alt', 'f4')
    time.sleep(1)
    
    # Try to locate and click the "Don't Save" button
    try:
        dont_save_button = pyautogui.locateOnScreen('dont_save_button.png', confidence=0.8)
        if dont_save_button:
            pyautogui.click(dont_save_button)
            print("Clicked 'Don't Save' button")
        else:
            print("Save dialogue not found, Excel may have closed without prompting")
    except pyautogui.ImageNotFoundException:
        print("Save dialogue not found, Excel may have closed without prompting")

def open_excel_with_macros(file_path):
    # Get the directory of the current script/executable
    base_path = getattr(sys, '_MEIPASS', os.path.dirname(os.path.abspath(__file__)))
    enable_button_image = os.path.join(base_path, 'enable_content.png')
    
    # Open Excel through the OS start menu or command line
    os.startfile(file_path)
    time.sleep(5)  # Wait for Excel to open

    # Custom timeout mechanism to locate the 'Enable Content' button
    timeout = 10  # 10 seconds timeout
    start_time = time.time()
    enable_button = None

    while (time.time() - start_time) < timeout:
        try:
            enable_button = pyautogui.locateCenterOnScreen(enable_button_image, confidence=0.8)
            if enable_button:
                pyautogui.click(enable_button)
                break
        except pyautogui.ImageNotFoundException:
            pass
        time.sleep(1)  # Check every 1 second

    if not enable_button:
        print("Enable Content button not found, continuing...")

    # Wait for any macros to finish running or other processing
    time.sleep(10)  # Adjust time based on expected macro execution time
    
    # Close Excel without saving
    close_excel_without_saving()

    # Close any cmd.exe windows that might have opened, except Anaconda prompt
    close_cmd_window()

def main():
    directory = r'C:\Users\student\Desktop\Corpus'  # Adjust the path to your files
    files = os.listdir(directory)
    excel_files = [file for file in files if file.endswith(('.xlsx', '.xlsm'))]
    
    for file in excel_files:
        full_path = os.path.join(directory, file)
        open_excel_with_macros(full_path)
        time.sleep(5)  # Adjust as needed between openings

if __name__ == '__main__':
    main()
