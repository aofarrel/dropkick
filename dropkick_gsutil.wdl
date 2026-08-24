version 1.0

workflow Dropkick_Gsutil {
	input {
		String destination_bucket    # ommit gs:// and trailing slashes, ex "gs://my_cool_bucket/" should be "my_cool_bucket"
		Array[File] files_to_upload
	}

	call dropkick_gsutil {
		input:
			destination_bucket = destination_bucket,
			files_to_upload = files_to_upload
	}
}

task dropkick_gsutil {
	input {
		String destination_bucket
		Array[File] files_to_upload
	}
	Int bigness = ceil(size(files_to_upload, "GB")) + 5
	
	command <<<
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] Booted into container"
		set -eu pipefail
		set +x
		for FILE in ~{sep=' ' files_to_upload}
		do
			BASENAME=$(basename "$FILE")
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] Uploading $BASENAME..."
			gsutil cp -n "$FILE" "gs://~{destination_bucket}/$BASENAME"
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished"
		done
	>>>

	runtime {
		cpu: 2
		disks: "local-disk " + bigness + " SSD"
		docker: "ashedpotatoes/dropkick:0.0.3"
		memory: "8 GB"
		preemptible: 2
	}
}