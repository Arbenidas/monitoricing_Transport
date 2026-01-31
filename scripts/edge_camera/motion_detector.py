import cv2
import time
import os
from collections import deque
import threading
# Placeholder for Gemini API
# import google.generativeai as genai

class SmartCamera:
    def __init__(self, camera_index=0):
        self.cap = cv2.VideoCapture(camera_index)
        self.background_subtractor = cv2.createBackgroundSubtractorMOG2(history=500, varThreshold=25, detectShadows=True)
        self.is_recording = False
        self.frame_buffer = deque(maxlen=300) # Buffer 10 seconds (assuming 30fps) of *potential* frames
        self.recording_buffer = []
        self.motion_start_time = 0
        self.min_recording_seconds = 3
        self.cooldown_seconds = 2
        self.last_motion_time = 0

    def start(self):
        print("🎥 Camera started. Press 'q' to quit.")
        
        while True:
            ret, frame = self.cap.read()
            if not ret:
                break

            # 1. Motion Detection
            fg_mask = self.background_subtractor.apply(frame)
            _, thresh = cv2.threshold(fg_mask, 244, 255, cv2.THRESH_BINARY)
            contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            
            motion_detected = False
            for contour in contours:
                if cv2.contourArea(contour) > 1500: # Threshold for "significant" size (ignore bugs/dust)
                    motion_detected = True
                    break

            # 2. Logic to Trigger Recording
            current_time = time.time()
            
            # Visual Debugging (Green Box if motion)
            if motion_detected:
                cv2.putText(frame, "MOTION DETECTED", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
                self.last_motion_time = current_time
                
                if not self.is_recording:
                    print("🚀 Motion started! Recording clip...")
                    self.is_recording = True
                    self.motion_start_time = current_time
                    self.recording_buffer = [] # Start fresh or include pre-buffer if needed

            # 3. Handle Recording State
            if self.is_recording:
                self.recording_buffer.append(frame)
                
                # Check if we should stop recording
                time_since_motion = current_time - self.last_motion_time
                duration = current_time - self.motion_start_time
                
                # Stop if no motion for 'cooldown' seconds AND we have min duration
                if time_since_motion > self.cooldown_seconds and duration > self.min_recording_seconds:
                    print(f"✅ Recording stopped. Duration: {duration:.2f}s. Frames: {len(self.recording_buffer)}")
                    self.is_recording = False
                    self._process_clip_async(list(self.recording_buffer))
                    self.recording_buffer = []

            # Display
            cv2.imshow('Smart Store Camera', frame)
            # cv2.imshow('Mask', fg_mask) # Debug mask

            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

        self.cap.release()
        cv2.destroyAllWindows()

    def _process_clip_async(self, frames):
        """Runs API upload in separate thread to not block camera."""
        threading.Thread(target=self._send_to_gemini, args=(frames,)).start()

    def _send_to_gemini(self, frames):
        print(f"☁️ Sending {len(frames)} frames to Gemini 1.5 Flash...")
        
        # --- PSEUDO CODE FOR GEMINI API ---
        # 1. Save frames to temporary video file (mp4)
        # video_path = self._save_to_temp_mp4(frames)
        
        # 2. Upload to Gemini File API
        # video_file = genai.upload_file(video_path)
        
        # 3. Prompt
        # model = genai.GenerativeModel('gemini-1.5-flash')
        # response = model.generate_content([
        #    "Analyze this CCTV footage of a store entrance.",
        #    "Count how many people enter and how many exit.",
        #    "Return JSON: { 'entries': int, 'exits': int }"
        #    video_file
        # ])
        
        # print("🤖 AI API Response:", response.text)
        
        # 4. Trigger Webhook/Firebase with result
        # -----------------------------------
        
        # SIMULATION
        time.sleep(2)
        print("✨ Simulation: Gemini says '1 Person Entered'")

if __name__ == "__main__":
    cam = SmartCamera()
    cam.start()
