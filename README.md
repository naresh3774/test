kubectl get namespace cnvrg -o json > tmp.json

then edit tmp.json and remove"kubernetes"
}, “spec”: { “finalizers”: [ “kubernetes” ] },

after editing it should look like this

}, “spec”: { “finalizers”: [ ] },

Open another terminal and Run kubectl proxy and hit the Curl


curl -k -H "Content-Type: application/json" -X PUT --data-binary @tmp.json http://127.0.0.1:8001/api/v1/namespaces/cnvrg/finalize