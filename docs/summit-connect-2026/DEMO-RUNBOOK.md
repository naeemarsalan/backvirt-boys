# Summit Connect Virt Demo Runbook

Presenter walkthrough for the deck "Accelerating Delivery: Self-Service Automation with Developer Portals and OpenShift Virtualization". Two live demos: slide 8 (the portal provisions a VM) and slide 15 (an alert drives an approval and a hot plug). Everything runs on AAP 2.6 (`aap-26` on the hammer cluster) and lands VMs on the virt cluster in project `vms-aap-day2`.

## Before you start

You need the na-launch VPN (SSH and RDP to the VMs use 172.16.2.x addresses) and three browser tabs signed in before the talk.

| Tab | Open this | Sign in as |
| --- | --- | --- |
| Portal (slide 8) | https://redhat-rhaap-portal-self-service-aap26.apps.hammer.na-launch.com | Sign in with RHAAP, your LDAP user or admin |
| AAP (both demos) | https://aap-26-aap-26.apps.hammer.na-launch.com | admin (secret `aap-26-admin-password`, namespace `aap-26` on hammer) or LDAP |
| OpenShift console (both demos) | https://console-openshift-console.apps.virt.na-launch.com/k8s/ns/vms-aap-day2/kubevirt.io~v1~VirtualMachine | ipaserver identity provider, your LDAP user |

The day before:

- [ ] Portal, Templates: the six OCP-Virt cards show (Create Virtual Machine, Create Windows VM, Delete, Start / Stop / Restart, Hot Plug, Patch).
- [ ] AAP, Automation Decisions, Rulebook Activations: "VM Resizing OCP-Virt" is Running.
- [ ] Console, project vms-aap-day2: at least one running RHEL VM at u1.small for slide 15 (demo-rhel9-02 is kept small).
- [ ] Optional: start a Windows VM from the portal so a finished one exists to show (20 to 30 minutes).
- [ ] Dry run slide 15 once, then shrink the VM back with Hot Plug VM Resources.

VM logins: RHEL `rhel` / `openshift`. Windows `Administrator` / `R3dh4t1!`.

## Slide 8: Self Service + Virtualization Provisioning

About 3 minutes end to end. Start it while talking through slides 4 to 7 if you want the VM ready by slide 8.

1. **Sign in to the portal** with "Sign in with RHAAP". First-time users approve one consent screen.
   ![Portal sign-in](screenshots/portal-signin.png)
2. **Templates**: click Start on "OCP-Virt: Create Virtual Machine".
   ![Portal templates](screenshots/portal-templates.png)
3. **Fill in the form.** Only the VM name needs typing.

   | Field | Type or pick | Notes |
   | --- | --- | --- |
   | VM Name | summit-rhel-01 | lower case, new name each run |
   | VM Namespace | vms-aap-day2 | default |
   | Instance Type | u1.small | u1.medium if you want to hot plug this VM later |
   | VM Preference | rhel.9 | default |
   | OS Boot Source | rhel9 | default |
   | Workload Label | rhel | default |
   | Network | net-200 | default; lab LAN with DHCP so you can SSH |

   Next, review, Run.
   ![Create VM form](screenshots/portal-create-vm-form.png)
4. **AAP, Automation Execution, Jobs**: the top job is "OCP-Virt: Create Virtual Machine". Open it and show the output (creates the VM, waits for an address, waits for SSH). This is the API call on slide 8, arrow 1.
   ![AAP jobs](screenshots/aap-jobs.png)
5. **Console, VirtualMachines in vms-aap-day2**: the VM appears within about 30 seconds, then Running. Click it for the IP (arrow 2).
   ![VM list](screenshots/ocp-vm-list.png)
   ![VM details](screenshots/ocp-vm-rhel-details.png)
6. **Access the VM**: `ssh rhel@<ip>` (password openshift) from a host on the VPN.

## Slide 8 variant: a Windows VM

Start early. The job returns in about 2 minutes once the installer boots; Windows Setup then runs unattended for 20 to 30 minutes with two reboots.

1. Templates, Start on "OCP-Virt: Create Windows VM (unattended install)".
2. Form:

   | Field | Type or pick | Notes |
   | --- | --- | --- |
   | VM Name | summit-win-01 | becomes the computer name, max 15 chars |
   | VM Namespace | vms-aap-day2 | default |
   | Instance Type | u1.medium | 4 GiB minimum |
   | Windows edition | 2 | Server 2022 Standard Desktop Experience. 1 Std Core, 4 DC Desktop, 3 DC Core |
   | Root disk size | 60Gi | default |
   | Network | net-200 | default |

   ![Create Windows VM form](screenshots/portal-create-win-form.png)
3. Watch Setup in the VM's Console tab. The answer file partitions, installs, sets the password, enables RDP, installs virtio guest tools at first logon.
   ![Windows Setup](screenshots/windows-setup-installing.png)
4. Finished VM: Details shows the IP and "Windows Server 2022 Standard Evaluation".
   ![Windows desktop](screenshots/windows-desktop.png)
   ![Windows VM details](screenshots/ocp-vm-win-details.png)
5. RDP as Administrator / R3dh4t1!.

## Slide 15: Event Driven Automation + OpenShift Virt

Stress to approval about 90 seconds; approve to execute about 60 seconds. Use a VM that is u1.small.

1. **Show the wiring** (optional): Automation Decisions, Rulebook Activations, "VM Resizing OCP-Virt" (Running, event stream "OCP-V VM Alerts"); then the "VM Scaling with Approval" workflow visualizer.
   ![EDA activation](screenshots/eda-activation.png)
   ![Workflow visualizer](screenshots/aap-workflow-visualizer.png)
2. **Stress the VM**: AAP, Templates, "OCP-Virt: Stress VM Memory (demo trigger)", rocket. Limit = `vms-aap-day2-demo-rhel9-02` (pick from the list). Leave the variables (8m, 85%). Launch.
   ![Stress template](screenshots/aap-jt-stress.png)
3. **Alert fires** (about 90 s): console, Observe, Alerting, rule VMHighMemoryUsage goes Pending then Firing. Alertmanager posts it to the AAP event stream (arrow 1).
   ![Alert rule](screenshots/ocp-alert-rule.png)
4. **EDA catches it**: Event Streams shows events received going up; the activation's fire count increments (arrow 2). It launched "Trigger VM Scaling Workflow", which launched the workflow (arrow 3).
   ![Event streams](screenshots/eda-event-streams.png)
5. **Approve**: Jobs, newest "VM Scaling with Approval" is Pending at the approval node. Approve from the bell icon or Administration, Workflow Approvals.
   ![Workflow pending](screenshots/aap-workflow-job.png)
   ![Workflow approvals](screenshots/aap-approvals.png)
6. **Hot plug**: "VM Scale Execute" runs (about 60 s); in the console the instance type goes u1.small to u1.medium with the VM still Running (arrows 4 and 5).

After the demo, shrink the VM back with the portal card "OCP-Virt: Hot Plug VM Resources".

## Day-2 templates if time allows

| Portal card | What it does | Fill in |
| --- | --- | --- |
| Start / Stop / Restart VM | power operation | operation, VM name, namespace |
| Hot Plug VM Resources | live instance-type change | VM name, namespace, new type |
| Patch VMs | dnf patching of discovered RHEL VMs | limit to one host; patch type all or security; reboot no |
| Delete Virtual Machine | removes the VM and disks | VM name, namespace |

## If something goes wrong

| Symptom | Check | Fallback |
| --- | --- | --- |
| Portal card missing | Templates, Sync now (auto every 15 min) | launch the job template from AAP |
| Portal sign-in loops | signed in to AAP as another user in a tab | sign out of AAP, sign in again |
| Create VM fails at "Wait for SSH" | VM has no DHCP address yet | wait a minute, show the VM anyway |
| Create VM fails immediately | name in use, or 401 from the virt API | new name; re-create the SA token if 401 |
| VM stuck Starting > 5 min | a launcher pod with that name was force-deleted earlier | delete and re-create under a new name; never `--grace-period=0` on virt-launcher pods |
| No alert after stress | Observe, Alerting; the hog dies on tiny VMs | send a test event from the event stream page |
| Alert fires, nothing in AAP | activation must be Running; restart it | launch the workflow by hand with vm_name and namespace |
| Windows stuck at "Press any key" | ISO volume replaced with stock media | rebuild with `aap_virt/windows-iso/remaster-noprompt.sh` |
| Everything slow on virt | nested SNO VMs eat CPU | stop hammer2-sno and asaran before the session |

## Reference

| Item | Where |
| --- | --- |
| AAP content | this branch, project `backvirt-boys` in aap-26 |
| Portal templates | Create Virtual Machine, Create Windows VM (unattended install), Delete, Start / Stop / Restart, Hot Plug, Patch |
| Hidden templates (label `internal`) | Trigger VM Scaling Workflow, VM Scale Request, VM Scale Execute, Stress VM Memory |
| Workflow | VM Scaling with Approval: request, approval, execute |
| EDA | activation VM Resizing OCP-Virt, rulebook `extensions/eda/rulebooks/webhook_port.yml`, event stream OCP-V VM Alerts |
| Virt alerting | PrometheusRule vm-high-memory-usage (>80% for 30 s) and AlertmanagerConfig vm-alerts-to-eda in vms-aap-day2 |
| AAP access to virt | SA `aap/ocp-virt-sa`, token secret `ocp-virt-sa-aap26-token`, credential "OCP-SA (virt.na-launch.com)" |
| Windows ISO | PVC `win2022-eval-iso` in vms-aap-day2, remastered with efisys_noprompt.bin |
