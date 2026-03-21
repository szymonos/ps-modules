# :material-format-letter-case: Naming Conventions

Kubectl aliases follow a strict, composable pattern: **k** + *verb* + *resource* + *options*

This makes it possible to generate **790+** aliases from a small set of building blocks.

## :material-play: Verb Prefixes

Every alias starts with `k`, followed by a verb abbreviation.

| Prefix | Kubectl verb |
| ------ | ------------ |
| `kg`   | `get`        |
| `kd`   | `describe`   |
| `krm`  | `delete`     |
| `ka`   | `apply`      |
| `kre`  | `replace`    |
| `krun` | `run`        |
| `kt`   | `top`        |
| `ksys` | kube-system  |

## :material-cube-outline: Resource Suffixes

The resource abbreviation follows the verb.

| Suffix | Resource   |
| ------ | ---------- |
| `po`   | Pod        |
| `dep`  | Deployment |
| `svc`  | Service    |
| `ing`  | Ingress    |
| `cm`   | ConfigMap  |
| `sec`  | Secret     |
| `ns`   | Namespace  |
| `no`   | Node       |

## :material-format-list-checks: Output Options

Output modifiers are appended at the end.

| Suffix  | Flag            |
| ------- | --------------- |
| `oyaml` | `-o yaml`       |
| `ojson` | `-o json`       |
| `owide` | `-o wide`       |
| `sl`    | `--show-labels` |
| `w`     | `--watch`       |
| `all`   | all namespaces  |

## :material-code-braces: Examples

Combine the parts to form any alias:

```text
kgpo        -> kubectl get pods
kgpooyaml   -> kubectl get pods -o yaml
kgpoowide   -> kubectl get pods -o wide
kgpoall     -> kubectl get pods --all-namespaces
kgpoallw    -> kubectl get pods --all-namespaces --watch
kdpo        -> kubectl describe pods
krmpo       -> kubectl delete pods
ksysgpo     -> kubectl get pods -n kube-system
kgsvc       -> kubectl get services
kgsvcoyaml  -> kubectl get services -o yaml
kgdep       -> kubectl get deployments
kgno        -> kubectl get nodes
kgnoowide   -> kubectl get nodes -o wide
```

!!! tip "Reading any alias"
    Break it down left to right: `kgpoallw` = **k** (kubectl) + **g** (get) + **po** (pods)
    \+ **all** (--all-namespaces) + **w** (--watch)
