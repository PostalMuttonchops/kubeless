# Add RBAC role and binding on top of kafka-zookeeper.jsonnet, to allow
# Kafka trigger controller to get/list/update/etc Kafka triggers in any namespace
local k = import "ksonnet.beta.1/k.libsonnet";
local objectMeta = k.core.v1.objectMeta;

local kafka = import "kafka-zookeeper.jsonnet";
local kafkaControllerAccount = kafka.kafkaControllerAccount;
local controller_roles = [
  {
    apiGroups: [""],
    resources: ["services", "configmaps"],
    verbs: ["get", "list"],
  },
  {
    apiGroups: ["kubeless.io"],
    resources: ["functions", "kafkatriggers"],
    verbs: ["get", "list", "watch", "update", "delete"],
  },
];

local clusterRole(name, rules) = {
    apiVersion: "rbac.authorization.k8s.io/v1beta1",
    kind: "ClusterRole",
    metadata: objectMeta.name(name),
    rules: rules,
};

local clusterRoleBinding(name, role, subjects) = {
    apiVersion: "rbac.authorization.k8s.io/v1beta1",
    kind: "ClusterRoleBinding",
    metadata: objectMeta.name(name),
    subjects: [{kind: s.kind, namespace: s.metadata.namespace, name: s.metadata.name} for s in subjects],
    roleRef: {kind: role.kind, apiGroup: "rbac.authorization.k8s.io", name: role.metadata.name},
};

local controllerClusterRole = clusterRole(
  "kafka-controller-deployer", controller_roles);

local controllerClusterRoleBinding = clusterRoleBinding(
  "kafka-controller-deployer", controllerClusterRole, [kafkaControllerAccount]
);

kafka + {
  controllerClusterRole: controllerClusterRole,
  controllerClusterRoleBinding: controllerClusterRoleBinding,
}
