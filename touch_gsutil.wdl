version 1.0

workflow Test_Upload_Gsutil {
	input {
		# ommit gs:// and trailing slashes, ex "gs://my_cool_bucket/" should be "my_cool_bucket"
		String destination_bucket
	}

	call touch_gsutil {
		input:
			destination_bucket = destination_bucket
	}

	# If you run this, the workflow will fail (intentionally)
	#call verify_no_overwrite_gsutil {
	#	input:
	#		destination_bucket = destination_bucket,
	#		run_after_touch = touch_gsutil.prevent_race_condition
	#}
}

task touch_gsutil {
	# This requires the account has storage.objects.list and storage.objects.create, even if we don't -n
	input {
		String destination_bucket
	}
	
	command <<<
		set -eu pipefail
		set +x
		touch foo.txt
		gsutil cp -n foo.txt gs://~{destination_bucket}/foo.txt
	>>>

	runtime {
		cpu: 2
		disks: "local-disk " + 10 + " HDD"
		docker: "ashedpotatoes/dropkick:0.0.2"
		memory: "4 GB"
		preemptible: 2
	}

	output {
		Boolean prevent_race_condition = true
	}
}

task verify_no_overwrite_gsutil {
	# This requires the account have storage.objects.list and storage.objects.create, even if we don't -n
	input {
		String destination_bucket
		Boolean run_after_touch #!UnusedDeclaration
	}
	
	command <<<
		set -eu pipefail
		set +x
		echo "some text here to make this not a zero byte file" > foo.txt
		gsutil cp -n foo.txt gs://~{destination_bucket}/foo.txt
	>>>

	runtime {
		cpu: 2
		disks: "local-disk " + 10 + " HDD"
		docker: "ashedpotatoes/dropkick:0.0.2"
		memory: "4 GB"
		preemptible: 2
	}
}