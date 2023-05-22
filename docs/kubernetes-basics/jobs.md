# Kubernetes Jobs

## Overview

In Kubernetes, Jobs allow you to create simple pods that execute a specific task to completion the number of times specified. Jobs are great for running scheduled tasks on your cluster. You can read more about jobs at the article below:

[Kubernetes JObs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)

### Job Creation and Deletion

Create a new manifest file called sample-job.yaml with the following contents:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: sample-job
spec:
  template:
    spec:
      containers:
      - name: ubuntu
        image: ubuntu:latest
        command: [ "/bin/bash", "-c", "--" ]
        args: [ "for i in {1..10}; do date; sleep 1; done;" ]
      restartPolicy: Never
```

The above job will run an ubuntu pod that executes a bash command, writing the date/time once every second for 10 seconds. 

```bash
# Create the job
kubectl apply -f sample-job.yaml

# Check the job status and the pods running the job
kubectl get jobs,pods

# Sample Output
NAME                   COMPLETIONS   DURATION   AGE
job.batch/sample-job   0/1           2s         2s

NAME                   READY   STATUS    RESTARTS   AGE
pod/sample-job-gzx6d   1/1     Running   0          2s

# Run the command again after a few seconds when the job is complete
kubectl get jobs,pods

# Sample Output
NAME                   COMPLETIONS   DURATION   AGE
job.batch/sample-job   1/1           16s        33s

NAME                   READY   STATUS      RESTARTS   AGE
pod/sample-job-gzx6d   0/1     Completed   0          33s

# Delete the job
kubectl delete -f sample-job.yaml
```

## Parallelism and Completions

One great feature of jobs, which make them very useful for batch processing, is the concept of parallelism and completions. You can easily set these to scale out your workload in batch scenarios.

Update your sample-job.yaml to look like the following:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: sample-job
spec:
  completions: 12
  parallelism: 3
  template:
    spec:
      containers:
      - name: ubuntu
        image: ubuntu:latest
        command: [ "/bin/bash", "-c", "--" ]
        args: [ "for i in {1..10}; do date; sleep 1; done;" ]
      restartPolicy: Never
```

Now run it again and watch.

```bash
# Deploy the job
kubectl apply -f sample-job.yaml

# Check the job execution
kubectl get jobs,pods

# Sample Output
NAME                   COMPLETIONS   DURATION   AGE
job.batch/sample-job   3/12          20s        20s

NAME                   READY   STATUS      RESTARTS   AGE
pod/sample-job-45hv4   0/1     Completed   0          20s
pod/sample-job-4kp2p   1/1     Running     0          5s
pod/sample-job-clfx6   1/1     Running     0          5s
pod/sample-job-cn6c2   0/1     Completed   0          20s
pod/sample-job-l7srv   1/1     Running     0          5s
pod/sample-job-zrm94   0/1     Completed   0          20s
```

## CronJob

If you want to run a job at a specific scheduled time, one variant of the Job is the CronJob. It's the same basic format as a job, but you can specify a schedule in 'Cron' format. You can read about the Cron schedule format at the link below:

[Cron](https://en.wikipedia.org/wiki/Cron)

Lets modify the job above to run once every minute. Update your sample-job.yaml to look like the yaml below. To break this down, this will create a CronJob that will run once every minute, as dictated by the schedule = "* * * * *" (i.e. every minute, every hour, every day of the month, every month, every day of the week). On that schedule it will run 6 completions of the job running them 3 at a time in parallel.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "* * * * *"
  jobTemplate:
    spec:
      completions: 6
      parallelism: 3
      template:
        spec:
          containers:
          - name: ubuntu
            image: ubuntu:latest
            command: [ "/bin/bash", "-c", "--" ]
            args: [ "for i in {1..10}; do date; sleep 1; done;" ]
          restartPolicy: Never
```

Run the CronJob and set a 'watch' to see the results.

```bash
# Deploy the cronjob
kubectl apply -f sample-job.yaml

# Run a watch
watch kubectl get cronjob,job,pods

# Sample output after 2 minutes
NAME                  SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/hello   * * * * *   False     1        3s              86s

NAME                       COMPLETIONS   DURATION   AGE
job.batch/hello-28079558   6/6           30s        63s
job.batch/hello-28079559   0/6           3s         3s

NAME                       READY   STATUS      RESTARTS   AGE
pod/hello-28079558-6nrp9   0/1     Completed   0          63s
pod/hello-28079558-g9vdz   0/1     Completed   0          63s
pod/hello-28079558-jl2q7   0/1     Completed   0          48s
pod/hello-28079558-slr4c   0/1     Completed   0          48s
pod/hello-28079558-tfghp   0/1     Completed   0          63s
pod/hello-28079558-vwclb   0/1     Completed   0          48s
pod/hello-28079559-7fzfh   1/1     Running     0          3s
pod/hello-28079559-j6r4t   1/1     Running     0          3s
pod/hello-28079559-w2fll   1/1     Running     0          3s
```

Delete the CronJob.

```bash
kubectl delete -f sample-job.yaml
```

## Conclusion

You should now have a basic undersatnding of the use of Jobs and CronJobs in Kubenretes. You can see more details at the following articles:

* [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
* [Cron Job](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

