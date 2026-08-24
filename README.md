# dropkick
Set of WDLs useful for transferring files out of a Terra VM into a specified Google bucket, without relying on the FireCloud API. Designed for and only tested upon Terra WDL workflows, but might work for Terra notebooks, or in other GCE environments. **These workflows will not work on local environments (ie your laptop) nor Terra's Azure backend.**

There are security implications for this process, so please make sure you actually need this:
* If you are simply trying to get your workflow output files into *any* Google bucket, you don't need this; simply set up your WDL to have workflow-level outputs and they will be depositied in your Terra workspace's Google bucket
* Workflow-level outputs' resulting Terra workspace URIs can be written to a Terra data table, which can be accessed programmatically using the FireCloud API and moved after a workflow has finished executing
* dropkick executes as a WDL task and therefore cannot move WDL-level logs such as `script` or the file delocalization log

## How does it work?
Every Terra workspace is linked to a Google service account. A service account is sort of a mini-account linked to a billing project. Every Terra workspace has its own service account. When running a WDL task on Terra, you create an emphermal VM which is "aware" of the workspace's service account. Once the VM spins up an instance of the Docker image specified in the task's `runtime` section, you can act as the service account within that Docker container, provided it has the right tools.

Once you know the service account's name (see below), you can set up your destination bucket to accept writes from that service account. 

## Recommended use
1. Set up your destination bucket. Recommendations:
	* You (or applicable stakeholder) should have admin access
	* Not public to the internet
	* Should not be used for anything else besides this project
	* Does not have fine-grained permissions
2. Run whoami.wdl in your Terra workspace to get the name of that workspace's service account
	* As of 2026, the service account name is not visible on Terra's UI ("Google Project ID" is something different), so you cannot skip this step unless you did it earlier.
3. In your destination bucket, give the workspace service account `storage.objects.create` permissions
	* This should be the only permission you need to grant
	* If you are managing permissions using the web interface (console.cloud.google.com) this role has the name "Storage Object Creator"
4. Verify your destination bucket does not contain a file named `foo.txt`
5. Run touch.wdl in your Terra workspace and verify it succeeds in Terra's UI, and that an empty file named `foo.txt` ends up in your destination bucket
6. Use dropkick.wdl to move the actual files (you'll probably just want to import its task)

## Alternative: Using gsutil instead of curl
`dropkick.wdl` and `touch.wdl` both bypass gsutil and call the Google Storage API directly. This allows you to grant very minimal permissions to the workspace service account. However, it may not be suitable for all use cases, and doesn't support resumable uploads. If you are willing to grant the service account more permissions (including, but possibly not limited to, `storage.objects.list`) then you can use `dropkick_gsutil.wdl` and `touch_gsutil.wdl` instead.

## Troubleshooting
### Make sure you grant the right account permissions
* Keep in mind that any time you change Terra workspaces, you'll be working with a different service account
* The service account is NOT "Google Project ID", nor is the username you use to log into Terra with
* The service account will likely have a name like `[long string of characters]@[Google Project ID].iam.gserviceaccount.com`

### `curl: (22) The requested URL returned error: 401` / curl times out or hangs when trying to call http://169.254.169.254 
This is expected behavior if you're running on a non-cloud backend. This is a [link-local IP](https://en.wikipedia.org/wiki/Link-local_address) that largely cannot be accessed from things that aren't GCE or AWS.

On the other hand, if you're getting 401s on Terra, check to see if "Uploading [file]..." appears in the logs. If no, curl failed to communicate with the metadata server. Try again. If you're using a Docker image you made yourself, compare your Dockerfile to the one in this repo; consider installing `ca-certificates`, `curl`, and `openssl` prior to pip installing `gsutil`. Also make sure you are using http, not https, when communicating with 169.254.169.254 

### `curl: (22) The requested URL returned error: 403`
Your service account does not have `storage.objects.create` permissions on your destination bucket. Verify the destination bucket URI (keep in mind to exclude the gs:// prefix) and that you granted the right account permissions (see above).

### `curl: (22) The requested URL returned error: 404`
You entered the bucket name incorrectly, or tried to put the file into a subdirectory (which currently isn't supported).

### `curl: (22) The requested URL returned error: 412`
A file with that name already exists in the bucket.

### `command not found`
If you copy-pasted code directly into an existing WDL task instead of importing the entire task, you might be using a Docker image that doesn't have `curl` or `gsutil`. Either import the full task, or fix your task's Docker image. Be aware gsutil requires python 3.9 - 3.13 as of Jan 2026.

### `Anonymous caller does not have storage.objects.list access to the Google Cloud Storage bucket.`
This should only ever happen with the gsutil versions of the workflows. If `touch.wdl` (the curl version) works but `touch_gsutil.wdl` doesn't work, your service account has `storage.objects.create` permissions but not the required additional `storage.objects.list` permissions needed for gsutil. Either use the curl version, or grant the additional permissions.

### Directory issues
If we ever get around to implementing a directory option, and your bucket has hierarchical namespace (HNS), the directory must already exist before trying to put a file in it.
