# default SQS Dead Letter Queue for the account.

module "sqs_dlq" {

  source = "git@github.com:wearetechnative/terraform-aws-sqs-dlq.git?ref=df97055f0ae7a2593170dc4b0dc20dd7720375c4"

  name       = "tn-shared-workloads"
  fifo_queue = false

}
