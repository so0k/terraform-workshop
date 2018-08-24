# S3 Uploads
resource "aws_s3_bucket_object" "custom_channel_manifest" {
  bucket = "${var.bucket_name}"
  key    = "${var.bucket_key_prefix}/custom-channel.yaml"
  source = "./modules/channels/templates/custom-channel-manifest.yaml"
  etag   = "${md5(file("./modules/channels/templates/custom-channel-manifest.yaml"))}"
}

resource "aws_s3_bucket_object" "addon_tiller" {
  bucket  = "${var.bucket_name}"
  key     = "${var.bucket_key_prefix}/tiller.swatmobile.io/k8s-1.9.yaml"
  content = "${data.template_file.addon_tiller.rendered}"
  etag    = "${md5(data.template_file.addon_tiller.rendered)}"
}

resource "aws_s3_bucket_object" "addon_ingress" {
  bucket  = "${var.bucket_name}"
  key     = "${var.bucket_key_prefix}/ingress.swatmobile.io/k8s-1.9.yaml"
  content = "${data.template_file.addon_ingress.rendered}"
  etag    = "${md5(data.template_file.addon_ingress.rendered)}"
}

resource "aws_s3_bucket_object" "addon_state_metrics" {
  bucket  = "${var.bucket_name}"
  key     = "${var.bucket_key_prefix}/state-metrics.swatmobile.io/k8s-1.9.yaml"
  content = "${data.template_file.addon_state_metrics.rendered}"
  etag    = "${md5(data.template_file.addon_state_metrics.rendered)}"
}

# S3 Sources
data "template_file" "addon_tiller" {
  template = "${file("./modules/channels/templates/addon-tiller.yaml")}"

  vars {
    addon_label = "tiller.swatmobile.io"

    # tiller clusterWide
    tiller_version     = "${var.tiller_version}"
    tiller_history_max = "${var.tiller_history_max}"
  }
}

data "template_file" "addon_ingress" {
  template = "${file("./modules/channels/templates/addon-ingress.yaml")}"

  vars {
    addon_label                         = "ingress.swatmobile.io"
    aws_region                          = "${var.aws_region}"
    skipper_version                     = "${var.skipper_version}"
    kube_ingress_aws_controller_version = "${var.kube_ingress_aws_controller_version}"
  }
}

data "template_file" "addon_state_metrics" {
  template = "${file("./modules/channels/templates/addon-state-metrics.yaml")}"

  vars {
    addon_label           = "state-metrics.swatmobile.io"
    state_metrics_version = "${var.kube_state_metrics_version}"
  }
}
