provider "aws" {
  region = "us-east-1"  # região
  access_key = "AKIA4T72PMKFX6P6PTWC"
  secret_key = "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"
}


# Criação do Security Group
resource "aws_security_group" "windows_server_2019" {
  name_prefix = "RDP-WinRM-SG"
  
  # Regra para permitir tráfego na porta do RDP (3389) a partir de qualquer endereço IP
  ingress {
    description = "Allow RDP traffic"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra para permitir tráfego na porta do WinRM (5986) a partir de qualquer endereço IP
  ingress {
    description = "Allow WinRM traffic"
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra para permitir tráfego de saída para qualquer endereço IP
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Criação da instância EC2
resource "aws_instance" "windows_server_2019" {
  ami                    = "ami-0ea6a9ded5194e937"  # ID da imagem do Windows Server 2019
  instance_type          = "t2.micro"  # Tipo da instância
  key_name               = "terraform_user"  # Nome da chave SSH
  associate_public_ip_address = true  # Associar um IP público à instância

  # Especifica o ID do security group criado acima para ser associado à instância
  vpc_security_group_ids = [aws_security_group.windows_server_2019.id]

  user_data = <<-EOF
    <powershell>
    # Criar novo usuário e definir senha
    $username = "filipe"
    $password = "102030"
    $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)
    New-LocalUser -Name $username -Password $cred

    # Configurações para permitir o acesso via WinRM na porta 5986
    winrm quickconfig -q
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'

    # Regras de firewall para permitir tráfego na porta 5986 e RDP (3389)
    New-NetFirewallRule -DisplayName "WinRM-HTTPS-In-TCP" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow
    netsh advfirewall firewall add rule name="RDP" dir=in action=allow protocol=TCP localport=3389
    </powershell>
  EOF
}

output "ec2_public_ip" {
  value = aws_instance.windows_server_2019.public_ip
}
