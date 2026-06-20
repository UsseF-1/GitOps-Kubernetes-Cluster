# COntainers [ 3 built images, 2 will be pulled from dockerhup]
---
## (Project Structure)
each image has its own Dockerfile 

- vote/   Dockerfile       # voting app (Python)  
- result/ Dockerfile       # to preview results  ( Node.js)
- worker/ Dockerfile       # as base no ui in it (.NET Core Core)
 worker.csproj
---

## (Services)
### (Vote Service)
* `python:3.11-slim` (slim:لتقليل المساحة ).
* Enviromental variable(Port):`80`.

### (Result Service)
*  `node:18-slim`
* Enviromental variable(Port):`80`.
### (Worker Service)
* *Multi-stage build*
  * Build Stage:`dotnet/sdk:7.0` لعمل الـ Restore والـ Publish.
  * Runtime Stage:`dotnet/runtime:7.0` لتشغيل الملفات النهائية فقط (reduce Image size).
---
## (To Build)

# build vote services 
docker build -t vote ./vote

# build result services 
docker build -t result ./result

# build worker services 
docker build -t worker ./worker
--- 
---

## (Environmental Variables)

### (Vote Service)
* **env:** `REDIS_HOST` (virtual value: `redis`)
### (Result Service)
* **env:** `DATABASE_URL`و `PORT`
---
### 2 pulled images
* docker pull redis:alpine 
* docker pull postgres:15-alpine
