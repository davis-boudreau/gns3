How to test quickly
Local Docker (standalone)

Set in kiosk.env:

ACCESS_MODE=standalone
NOVNC_ENABLE=true
VNC_PASSWORD=changeme

Then:

docker compose up --build

GNS3
Set in kiosk.env:

ACCESS_MODE=gns3
NOVNC_ENABLE=false

In GNS3 you should use VNC Console only.