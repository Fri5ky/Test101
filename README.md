------------------------
Method 1: Nginx (Permanent)
------------------------


1. Install Nginx:
   sudo apt update
   sudo apt install -y nginx


2. Start and enable Nginx:
   sudo systemctl start nginx
   sudo systemctl enable nginx


3. Create your YAML file:
   nano ~/setup-config.yaml #Create any file you want to host eg .sh .yaml


   Example content:
   # Sample configuration
   system:
     hostname: "ubuntu-server"
   users:
     - name: "admin"
       sudo: true
   packages:
     - git
     - curl
     - nginx


   (Save with Ctrl+O, Enter, Ctrl+X)


4. Copy to web directory:
   sudo cp ~/setup-config.yaml /var/www/html/
   sudo chmod 644 /var/www/html/setup-config.yaml

4. Copy to web directory:
   sudo cp ~/script1.sh /var/www/html/
   sudo chmod 644 /var/www/html/script1.sh


5. Verify access:
   curl http://localhost/setup-config.yaml
   or from another machine:
   curl http://10.247.43.131/setup-config.yaml


   wget http://YOUR_SERVER_IP:8000/setup-config.yaml
