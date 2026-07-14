# phone-store

## Docker setup

This repository is now configured to run with Docker using `docker-compose`.

### Available containers

- `mongo`: MongoDB database
- `backend`: ASP.NET Core API
- `frontend`: React frontend served by nginx

### Run locally

1. From the repository root:

```bash
docker compose up --build
```

2. Open the frontend in your browser:

- http://localhost:3000

3. The backend API will be available at:

- http://localhost:8080

### Notes

- The React app is configured to proxy `/api` to the backend service.
- MongoDB persistence is stored in a named Docker volume `mongo-data`.
