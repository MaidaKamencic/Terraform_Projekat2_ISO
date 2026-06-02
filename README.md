# Recipe Organizer – Terraform

Kontejnerizovana web aplikacija za recepte, deployovana na AWS infrastrukturi koristeći Docker, RDS, S3, Application Load Balancer i Terraform.

---

## Struktura repozitorija

```
terraform-recipe/
├── main.tf          # VPC, EC2, RDS, ALB, S3, Security Groups
├── variables.tf     # Varijable
├── outputs.tf       # Output vrijednosti
├── assets/          # Statički fajlovi
│   └── logo.png
└── README.md

```

---
## Arhitektura

VPC - sa 2 public i 2 private subneta u us-east-1a i us-east-1b
Frontend — React aplikacija na EC2 instancama u public subnetima iza ALB-a
Backend — Flask aplikacija na EC2 instancama u public subnetima iza ALB-a
RDS — PostgreSQL 16 baza u private subnetima
S3 — bucket za statičke fajlove (logo)
Application Load Balancer — Load Balancer za frontend i backend instance


## Preduslovi
Potrebno je imati instaliran Terrafom i AWS CLI , ukoliko nemate instalirane alate, možete ih preuzeti sa zvaničnih stranica:

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0

- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0

- AWS Academy sandbox sesija pokrenuta

---

## Konfiguracija kredencijala

Nakon pokretanja lab sesije na AWS Academy, potrebno je kliknuti na AWS Details , nakon toga na Show  i kopirati AWS Access Key, Secret Key i Session Token, te ih postaviti :

aws configure
AWS Access Key ID: (iz Sandbox)
AWS Secret Access Key: (iz Sandbox)
Default region: us-east-1
Default output format: json

Također, postoji jos jedna nacin da se postave kredencijali, a to je preko export komandi:

```bash
export AWS_ACCESS_KEY_ID="aws_access_key_id"
export AWS_SECRET_ACCESS_KEY="aws_secret_access_key"
export AWS_SESSION_TOKEN="aws_session_token"
```

---

## Pokretanje

### 1. Kloniranje repozitorija

```bash
git clone https://github.com/MaidaKamencic/Terraform_Projekat2_ISO.git
cd Terraform_Projekat2_ISO
```

### 2. Inicijalizacija

```bash
terraform init
```

### 3. Pregled promjena

```bash
terraform plan
```

### 4. Deployment

```bash
terraform apply
```
Nakon ove komande, Terraform će prikazati plan promjena i tražiti potvrdu. Upiši `yes` da nastaviš sa kreiranjem infrastrukture.

### 5. S3 bucket – napomena

S3 bucket je zakomentiran u `main.tf` zbog ograničenja AWS Academy sandboxa. S3 bucket se kreira ručno u AWS konzoli, a assets se uploaduju direktno.

---

## Outputi

Nakon uspješnog `terraform apply`

Dobit ćeš output vrijednosti poput:

alb_url = "ovdje_je_url_za_aplikaciju"
ec2_instance_1_public_ip = "a.b.c.d"
ec2_instance_2_public_ip = "e.f.g.h"
rds_endpoint = "ovdje_je_url_za_rds"
rds_port = 5432
s3_bucket_name = "recipes-app-static-assets"


Napomena:

Potrebno je sačekati oko 1 minute nakon terraform apply prije otvaranja alb_url. Ako otvorite link prerano, moguće je da dobijete grešku 502 Bad Gateway dok se svi servisi (posebno RDS i containeri) ne podignu.


## Uništavanje infrastrukture

```bash
terraform destroy
```

Snimak ručnog deploymenta i tehničke dokumentacije je dostupan preko sljedećeg linka:
https://drive.google.com/drive/folders/1ibcg4D4Yzpk84zF_JRH9ChIxpfNYxkHh?usp=drive_link
