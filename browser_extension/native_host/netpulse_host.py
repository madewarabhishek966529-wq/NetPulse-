import sys
import os
import json
import struct
import time

def read_message():
    raw_length = sys.stdin.buffer.read(4)
    if len(raw_length) == 0:
        return None
    length = struct.unpack('@I', raw_length)[0]
    data = sys.stdin.buffer.read(length).decode('utf-8')
    return json.loads(data)

def send_message(message):
    encoded = json.dumps(message).encode('utf-8')
    sys.stdout.buffer.write(struct.pack('@I', len(encoded)))
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()

def main():
    # Ensure incoming queue directory exists in LocalAppData
    local_app_data = os.environ.get('LOCALAPPDATA', os.path.expanduser('~'))
    incoming_dir = os.path.join(local_app_data, 'NetPulse', 'incoming')
    os.makedirs(incoming_dir, exist_ok=True)

    while True:
        try:
            msg = read_message()
            if msg is None:
                break
            
            action = msg.get('action', 'download')
            url = msg.get('url', '')
            file_name = msg.get('fileName', '')
            referrer = msg.get('referrer', '')
            cookies = msg.get('cookies', '')

            if action == 'ping':
                send_message({"status": "ok", "version": "1.0.0", "app": "NetPulse"})
                continue

            if url:
                # Write to incoming task file
                task_id = f"task_{int(time.time() * 1000)}"
                task_file = os.path.join(incoming_dir, f"{task_id}.json")
                with open(task_file, 'w', encoding='utf-8') as f:
                    json.dump({
                        "url": url,
                        "fileName": file_name,
                        "referrer": referrer,
                        "cookies": cookies,
                        "timestamp": time.time()
                    }, f, indent=2)

                send_message({
                    "status": "success",
                    "message": "Download forwarded to NetPulse",
                    "taskId": task_id
                })
            else:
                send_message({"status": "error", "message": "Missing URL"})
        except Exception as e:
            send_message({"status": "error", "message": str(e)})
            break

if __name__ == '__main__':
    main()
