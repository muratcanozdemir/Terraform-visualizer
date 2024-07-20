from fastapi import FastAPI, HTTPException, UploadFile, File, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
import json
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError
from typing import Dict, Any
from parser import TerraformStateParser

app = FastAPI()

templates = Jinja2Templates(directory="templates")

def get_remote_state_mapping(repo_name, env): 
    data = {}
    if env == 'dev':
        account_id = 12321873918
    elif env == 'prod':
        account_id = 98384939239
    else:
        account_id = 0

    data['bucket'] = f'bnt-tf-state-{env}'
    data['key'] = f'bnt-{repo_name}-{env}'
    data['role_arn'] = f'arn:aws:iam::{account_id}:role/gh-oidc-{repo_name}-{env}'
    return data


class LoadStateRequest(BaseModel):
    repo_name: str
    environment: str

@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.post("/upload_state")
async def upload_state(file: UploadFile = File(...)):
    try:
        content = await file.read()
        state = json.loads(content.decode('utf-8'))

        # Parse the state and initialize the parser
        global current_parser
        current_parser = TerraformStateParser(state)
        initial_resource_id = next(iter(current_parser.graph))  # Get the first resource ID as initial

        return JSONResponse(content={"success": True, "initial_resource_id": initial_resource_id})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/load_state")
async def load_state(request: LoadStateRequest):
    repo_name = request.repo_name
    environment = request.environment

    repo_env_details = get_remote_state_mapping(repo_name, environment)

    if not repo_env_details:
        raise HTTPException(status_code=400, detail="Invalid repository or environment")

    bucket = repo_env_details['bucket']
    key = repo_env_details['key']
    role_arn = repo_env_details['role_arn']

    try:
        # Assume the specified AWS role
        sts_client = boto3.client('sts')
        assumed_role = sts_client.assume_role(
            RoleArn=role_arn,
            RoleSessionName='TerraformStateSession'
        )

        credentials = assumed_role['Credentials']
        s3_client = boto3.client(
            's3',
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken']
        )

        # Fetch the Terraform state file from S3
        s3_object = s3_client.get_object(Bucket=bucket, Key=key)
        state_content = s3_object['Body'].read().decode('utf-8')
        state = json.loads(state_content)

        # Parse the state and initialize the parser
        global current_parser
        current_parser = TerraformStateParser(state)
        initial_resource_id = next(iter(current_parser.graph))  # Get the first resource ID as initial

        return JSONResponse(content={"success": True, "initial_resource_id": initial_resource_id})
    except (NoCredentialsError, PartialCredentialsError) as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/lineage/{resource_id}")
async def get_lineage(resource_id: str):
    if 'current_parser' not in globals():
        raise HTTPException(status_code=500, detail="State not loaded")
    
    lineage = current_parser.get_lineage(resource_id)
    return JSONResponse(content=lineage)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
