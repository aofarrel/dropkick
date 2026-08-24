version 1.0

# !!! THIS ONLY WORKS WHEN RUNNING ON GOOGLE CLOUD (INCLUDING TERRA) !!!
# !!! IF YOU RUN THIS WORKFLOW LOCALLY, IT WILL JUST HANG / TIME OUT !!!

workflow WhoAmI {
	input {
		Boolean you_can_leave_this_blank = true
	}

	call get_service_account_name {
		input:
			unused_input = you_can_leave_this_blank
	}

	output {
		String service_account = get_service_account_name.service_account
	}

}

task get_service_account_name {
	input {
		Boolean unused_input #!UnusedDeclaration
	}
	
	command <<<
		curl -H "Metadata-Flavor: Google" \
			http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email > identity.txt
	>>>

	output {
		String service_account = read_string("identity.txt")
	}

	runtime {
		cpu: 2
		disks: "local-disk " + 10 + " HDD"
		docker: "ashedpotatoes/dropkick:0.0.3"
		memory: "4 GB"
		preemptible: 2
	}

}