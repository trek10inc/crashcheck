# Crashcheck Docker Container

This Docker container is meant to be run as Kubernetes job that will check the number of restarts encountered. Once activated, the image will perform basic GET requests to a URL and exit with a return code of zero if a series of successful responses are received.

This container is configured via the use of the following environment variables.
- **INTERVAL**: How frequently (in seconds) do we run a check
- **COUNT**: Number of checks to run. If set to value greater than zero, DURATION is ignored
- **MAX_DURATION**: Set max duration to limit check script to a specific duration if COUNT is used
- **DURATION**: How long (in seconds) does the job run if COUNT is not used
- **CRASH_LIMIT**: How many pod crashes the check script is willing to tolerate before exiting with a non-zero return code
- **HASH**: The "pod-template-hash" value to use as a selector when grouping pods to test
- **DEBUG**: Set this to enable debug output

Caveats related to the check script that is run within this container.
- COUNT and DURATION variables are mutually exclusive
- The check script will exit with a non-zero return code when CRASH_LIMIT has been reached
- The pod running this container will need RBAC permissions that grant it read access to pod information (see below)

A good reference for setting environments variables for containers can be found at the following link.

[Define Environment Variables for a Container](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)

This container was built to accompany a blog post related to using Argo Rollouts to revert failed Kubernetes deployments. Please reference the following link for more specifics on how it is used.

[Exploring GitOps with Argo Part 2](https://www.trek10.com/blog/exploring-gitops-with-argo-part-2)

The following Kubernetes resources can be utilized to create and bind a role to a service account that can be associated with a pod such that it can read pod statuses for a given namespace.

    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: read-pod-status
    rules:
    - apiGroups: [""]
      resources: ["pods"]
      verbs: ["get", "watch", "list"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: read-pod-status-binding
      namespace: default
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: read-pod-status
    subjects:
    - kind: ServiceAccount
      name: read-pod-status-sa
      namespace: default
    ---
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: read-pod-status-sa
      namespace: default

You can assign a service account to a pod once these resources have been provisioned using the “spec.serviceAccountName” field.
