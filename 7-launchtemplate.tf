resource "aws_launch_template" "app1_LT" {
  name_prefix   = "app1_LT"
  image_id      = "ami-05caa5aa0186b660f"  
  instance_type = "t2.micro"

  key_name = "ap_southeast_cloudwalkers"

  vpc_security_group_ids = [aws_security_group.app1-sg01-servers.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd

    # Get the IMDSv2 token
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

    # Background the curl requests
    curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4 &> /tmp/local_ipv4 &
    curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone &> /tmp/az &
    curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ &> /tmp/macid &
    wait

    macid=$(cat /tmp/macid)
    local_ipv4=$(cat /tmp/local_ipv4)
    az=$(cat /tmp/az)
    vpc=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$macid/vpc-id)

    # Create HTML file
    cat <<-HTML > /var/www/html/index.html
    <!doctype html>
    <html lang="en" class="h-100">
    <head>
    <title>Cloudwalkers Conquer Singapore</title>
    </head>
    <body>
    <div>
    <h1>Saturn</h1>
    <h1>Planting our Flag in Singapore</h1>
    <p><b>Instance Name:</b> $(hostname -f) </p>
    <p><b>Instance Private Ip Address: </b> $local_ipv4</p>
    <p><b>Availability Zone: </b> $az</p>
    <p><b>Virtual Private Cloud (VPC):</b> $vpc</p>
    <img src="https://images.salsify.com/image/upload/s--r2Vqk9Go--/q0x2mwwjsfegrtzccyhv">
    </div>
    </body>
    </html>
    HTML

    # Clean up the temp files
    rm -f /tmp/local_ipv4 /tmp/az /tmp/macid
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "app1_LT"
      Service = "application1"
      Owner   = "Cloudwalkers"
      Planet  = "Saturn"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
