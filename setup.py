from setuptools import setup, find_packages

setup(
    name="terraform_state_visualizer",
    version="0.1",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "fastapi",
        "uvicorn",
        "boto3",
    ],
    entry_points={
        "console_scripts": [
            "terraform-state-visualizer=app:main",
        ],
    },
)
