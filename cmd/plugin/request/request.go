/*
Copyright 2019 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package request

import (
	"bytes"
	"fmt"
	"io"
	"strconv"
	apiv1 "k8s.io/api/core/v1"
	"k8s.io/api/extensions/v1beta1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/cli-runtime/pkg/genericclioptions"
	"k8s.io/client-go/kubernetes/scheme"
	corev1 "k8s.io/client-go/kubernetes/typed/core/v1"
	extensions "k8s.io/client-go/kubernetes/typed/extensions/v1beta1"
	"k8s.io/client-go/tools/remotecommand"
	"k8s.io/ingress-nginx/cmd/plugin/util"
)

const (
	DefaultIngressDeploymentName     = "nginx-ingress-controller"
	DefaultIngressServiceName = "ingress-nginx"
)

// NamedPodExec finds a pod with the given name, executes a command inside it, and returns stdout
func NamedPodExec(flags *genericclioptions.ConfigFlags, podName string, cmd []string) (string, error) {
	pod, err := getNamedPod(flags, podName)
	if err != nil {
		return "", err
	}
	return podExec(flags, &pod, cmd)
}

// DeploymentPodExec finds an pod for the given deployment in the given namespace, executes a command inside it, and returns stdout
func DeploymentPodExec(flags *genericclioptions.ConfigFlags, deployment string, cmd []string) (string, error) {
	pod, err := getDeploymentPod(flags, deployment)
	if err != nil {
		return "", err
	}

	return podExec(flags, &pod, cmd)
}

// NamedPodLogs returns an io.Reader of the logs for the pod with the given name
func NamedPodLogs(flags *genericclioptions.ConfigFlags, podName string, follow bool) (io.Reader, error) {
	pod, err := getNamedPod(flags, podName)
	if err != nil {
		return nil, err
	}

	return podLogs(flags, &pod, follow)
}

// NamedPodLogs returns an io.Reader of the logs for a pod in the given deployment
func DeploymentPodLogs(flags *genericclioptions.ConfigFlags, deployment string, follow bool) (io.Reader, error) {
	pod, err := getDeploymentPod(flags, deployment)
	if err != nil {
		return nil, err
	}

	return podLogs(flags, &pod, follow)
}

func podLogs(flags *genericclioptions.ConfigFlags, pod *apiv1.Pod, follow bool) (io.Reader, error) {
	config, err := flags.ToRESTConfig()
	if err != nil {
		return nil, err
	}

	client, err := corev1.NewForConfig(config)
	if err != nil {
		return nil, err
	}

	namespace, _, err := flags.ToRawKubeConfigLoader().Namespace()
	if err != nil {
		return nil, err
	}

	req := client.RESTClient().Get().
	    Namespace(namespace).
	    Name(pod.Name).
	    Resource("pods").
	    SubResource("log").
	    Param("follow", strconv.FormatBool(follow))

	return req.Stream()
}

func podExec(flags *genericclioptions.ConfigFlags, pod *apiv1.Pod, cmd []string) (string, error) {
	config, err := flags.ToRESTConfig()
	if err != nil {
		return "", err
	}

	client, err := corev1.NewForConfig(config)
	if err != nil {
		return "", err
	}

	namespace, _, err := flags.ToRawKubeConfigLoader().Namespace()
	if err != nil {
		return "", err
	}

	restClient := client.RESTClient()

	req := restClient.Post().
		Resource("pods").
		Name(pod.Name).
		Namespace(namespace).
		SubResource("exec")

	req.VersionedParams(&apiv1.PodExecOptions{
		Command:   cmd,
		Stdin:     false,
		Stdout:    true,
		Stderr:    false,
		TTY:       false,
	}, scheme.ParameterCodec)

	exec, err := remotecommand.NewSPDYExecutor(config, "POST", req.URL())

	if err != nil {
		return "", err
	}

	stdout := bytes.NewBuffer(make([]byte, 0))
	err = exec.Stream(remotecommand.StreamOptions{
		Stdout: stdout,
	})

	return stdout.String(), err
}

func getDeploymentPods(flags *genericclioptions.ConfigFlags, deployment string) ([]apiv1.Pod, error) {
	pods, err := getPods(flags)
	if err != nil {
		return make([]apiv1.Pod, 0), err
	}

	ingressPods := make([]apiv1.Pod, 0)
	for _, pod := range pods {
		if pod.Spec.Containers[0].Name == deployment {
			ingressPods = append(ingressPods, pod)
		}
	}

	return ingressPods, nil
}

func getNamedPod(flags *genericclioptions.ConfigFlags, name string) (apiv1.Pod, error) {
	allPods, err := getPods(flags)
	if err != nil {
		return apiv1.Pod{}, err
	}

	for _, pod := range allPods {
		if pod.Name == name {
			return pod, nil
		}
	}

	return apiv1.Pod{}, fmt.Errorf("Pod %v not found in namespace %v", name, util.GetNamespace(flags))
}

func getDeploymentPod(flags *genericclioptions.ConfigFlags, deployment string) (apiv1.Pod, error) {
	ings, err := getDeploymentPods(flags, deployment)
	if err != nil {
		return apiv1.Pod{}, err
	}

	if len(ings) == 0 {
		return apiv1.Pod{}, fmt.Errorf("No pods for deployment %v found in namespace %v", deployment, util.GetNamespace(flags))
	}

	return ings[0], nil
}

func getPods(flags *genericclioptions.ConfigFlags) ([]apiv1.Pod, error) {
	namespace := util.GetNamespace(flags)

	rawConfig, err := flags.ToRESTConfig()
	if err != nil {
		return make([]apiv1.Pod, 0), err
	}

	api, err := corev1.NewForConfig(rawConfig)
	if err != nil {
		return make([]apiv1.Pod, 0), err
	}

	pods, err := api.Pods(namespace).List(metav1.ListOptions{})
	if err != nil {
		return make([]apiv1.Pod, 0), err
	}

	return pods.Items, nil
}

// GetIngressDefinitions returns an array of Ingress resource definitions
func GetIngressDefinitions(flags *genericclioptions.ConfigFlags, namespace string) ([]v1beta1.Ingress, error) {
	rawConfig, err := flags.ToRESTConfig()
	if err != nil {
		return make([]v1beta1.Ingress, 0), err
	}

	api, err := extensions.NewForConfig(rawConfig)
	if err != nil {
		return make([]v1beta1.Ingress, 0), err
	}

	pods, err := api.Ingresses(namespace).List(metav1.ListOptions{})
	if err != nil {
		return make([]v1beta1.Ingress, 0), err
	}

	return pods.Items, nil
}

// GetServiceByName finds and returns the service definition with the given name
func GetServiceByName(flags *genericclioptions.ConfigFlags, name string, services *[]apiv1.Service) (apiv1.Service, error) {
	if services == nil {
		servicesArray, err := getServices(flags)
		if err != nil {
			return apiv1.Service{}, err
		}
		services = &servicesArray
	}
	
	for _, svc := range *services {
		if svc.Name == name {
			return svc, nil
		}
	}

	return apiv1.Service{}, fmt.Errorf("Could not find service %v in namespace %v", name, util.GetNamespace(flags))
}

func getServices(flags *genericclioptions.ConfigFlags) ([]apiv1.Service, error) {
	namespace := util.GetNamespace(flags)

	rawConfig, err := flags.ToRESTConfig()
	if err != nil {
		return make([]apiv1.Service, 0), err
	}

	api, err := corev1.NewForConfig(rawConfig)
	if err != nil {
		return make([]apiv1.Service, 0), err
	}

	services, err := api.Services(namespace).List(metav1.ListOptions{})
	if err != nil {
		return make([]apiv1.Service, 0), err
	}

	return services.Items, nil

}
