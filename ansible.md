# Ansible Reference

A condensed (~10%) boil-down of Ansible's official documentation, weighted toward what this repo
actually does: managing local macOS user accounts and shared-folder permissions via
`ansible_connection: local`. Every claim below is sourced from a live fetch of the cited
docs.ansible.com / developer.apple.com / support.apple.com page, not recalled from memory. Where a
claim could not be verified against a live source, it's flagged explicitly rather than asserted.

Full docs: https://docs.ansible.com/ansible/latest/

## 1. Inventory & Variables

Source: [intro_inventory.html](https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_inventory.html), [playbooks_variables.html](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html), [intro_patterns.html](https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_patterns.html)

- An **inventory** lists the managed hosts. INI or YAML; default location `/etc/ansible/hosts`.
  INI groups use `[groupname]` brackets; YAML groups use `groupname: hosts: <host>:` mappings.
- **`group_vars/<name>` and `host_vars/<name>` can each be either a single file or a directory of
  files**, read in lexicographical order — this repo's per-colleague layout relies on exactly this.
  Rationale per the docs: split a file "when it gets too big."
- **Multiple/directory-based inventory sources**: `-i` can be passed more than once (sources merge
  in the order given), or pointed at a *directory*, in which case "Ansible reads and loads files
  from the top directory down in alphabetically sorted order" — the docs recommend numeric
  filename prefixes to control merge precedence explicitly.
- **Variable precedence** (lowest → highest, relevant excerpt): CLI values → role defaults →
  inventory group vars → inventory `group_vars/all` → playbook `group_vars/all` → inventory
  `group_vars/*` (other groups) → playbook `group_vars/*` → inventory host vars → inventory
  `host_vars/*` → playbook `host_vars/*` → facts → play/role/task vars → registered vars → role
  params → include params → **extra vars (`-e`) always win**. `host_vars` outranks `group_vars` at
  every corresponding scope.
- **Patterns / `--limit`**: `all`/`*`, `host1:host2` (union), `webservers:!atlanta` (exclusion),
  `webservers:&staging` (intersection), wildcards, regex (`~...`). `--limit` restricts which
  matched hosts actually run, e.g. `--limit 'all:!host1'`, or `--limit @retry_hosts.txt`.

## 2. Playbooks & Roles

Source: [playbooks_intro.html](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html), [playbooks_privilege_escalation.html](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_privilege_escalation.html), [playbooks_reuse_roles.html](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html), [playbooks_blocks.html](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_blocks.html), [playbooks_tags.html](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_tags.html), [playbooks_checkmode.html](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_checkmode.html)

- A **play** targets `hosts` and runs one or more **tasks**, each task one module; by default all
  matched hosts finish a task before the next task starts. `gather_facts` (default **on**) runs the
  `setup` module first to collect host facts.
- Execution order in a play using `roles:`: `pre_tasks` → their handlers → each role in listed
  order (including that role's dependencies) → the play's own `tasks:` → their handlers →
  `post_tasks` → their handlers. Roles listed under `roles:` (or via `import_role`) are static and
  always run before other tasks; `include_role` is dynamic and runs inline where it appears.
- **Role directory skeleton** (none strictly required, but this is the recognized shape):
  `tasks/main.yml`, `handlers/main.yml`, `defaults/main.yml` (lowest-priority vars),
  `vars/main.yml` (high-priority vars), `files/`, `templates/` (Jinja2 `.j2`), `meta/main.yml`
  (dependencies/Galaxy metadata).
- **block / rescue / always**: `block` groups tasks and runs them sequentially until a failure;
  `rescue` runs only on a block failure (like exception handling — success there clears the failed
  state); `always` runs regardless, for cleanup. `ansible_failed_task` /
  `ansible_failed_result` are available inside `rescue`.
- **Tags**: apply to tasks, blocks, plays, or roles. Reserved names: `always` (runs unless
  `--skip-tags always`), `never` (skipped unless explicitly requested), `tagged`, `untagged`, `all`.
- **`become`**: `become: true` is what activates privilege escalation — **not implied** by setting
  `become_user` alone (deliberately, so `become_user` can be set independently at host/group
  level). `become_method` defaults to `ansible.cfg`'s setting (typically `sudo`); other supported
  methods include `su`, `pfexec`, `doas`, `machinectl`. CLI flags outrank task-level, which
  outranks play-level, which outranks host/group vars, which outranks `ansible.cfg`.
- **`--check` / `--diff`**: `--check` simulates a run — modules that support check mode report what
  *would* change; unsupported modules just do nothing silently. Per-task override with
  `check_mode: true/false`. `--diff` shows before/after content (useful for `file`/`template`/
  `user`); combine as `--check --diff`; disable per task with `diff: false` to avoid leaking
  sensitive content into output.

## 3. Local User/Group/File Modules & Privilege Escalation

Source: [user_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html), [group_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/group_module.html), [file_module.html](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html), [ansible.posix.acl](https://docs.ansible.com/ansible/latest/collections/ansible/posix/acl_module.html), [local connection](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/local_connection.html)

- **`ansible.builtin.user`**: `name` (required), `uid` (+ `non_unique: true` to allow a duplicate
  UID), `group` (primary group, by name), `groups` (supplementary — **replaces** existing
  supplementary membership by default; `append: true` to add instead of replace), `shell`,
  `comment` (GECOS), `state: present|absent`, `create_home` (default `true`), `system` (default
  `false`, **not modifiable on an existing account** — changing it later has no effect),
  `password` (must already be hashed; not hashed by the module). Fully idempotent and
  check-mode-supported: re-running with identical params is a no-op.
- **`ansible.builtin.group`**: `name`, `gid`, `state`, `system`, `non_unique` (requires `gid`,
  **documented as unsupported on macOS and BusyBox**), `force` (delete even if it's a user's
  primary group — also platform-dependent, not applicable on macOS/BSD/BusyBox).
  **GID collision behavior**: if the requested `gid` is already taken by a different group, the
  underlying `groupadd` call **fails the task outright** — it does not silently reassign, rename,
  or skip. This is directly relevant to this repo: nothing pre-checks whether
  `agent_accounts_group_gid` collides with a pre-existing group before `apply` runs.
- **`ansible.builtin.file`**, `state: directory`: creates missing intermediate parents too. `mode`
  as octal (quote it — `'2775'`) or symbolic (`u+rwx`). Leading digit: `2` = setgid, `1` = sticky,
  `4` = setuid. `owner`/`group` take names; a purely numeric string is read as a UID/GID.
  `recurse: true` applies mode/owner/group to existing contents (this repo's `shared_surface` role
  does **not** set `recurse`, so it only ever touches the top-level directory itself).
- **`ansible.posix.acl` is a separate collection, not `ansible.builtin`**, requires
  `setfacl`/`getfacl`, and its own docs state verbatim: *"As of Ansible 2.0, this module only
  supports Linux distributions."* **It does not work on macOS at all** — see §4 for the macOS-native
  ACL mechanism.
- **`local` connection plugin** (`ansible_connection: local`, what this repo uses): still in
  `ansible.builtin`. Runs tasks directly on the control node, no SSH. The configured remote user is
  ignored — tasks run as whichever OS user invoked `ansible-playbook`. `become` still works the same
  way over a local connection.

## 4. Ansible on macOS — Local Users & Folder Permissions

This is the section most directly relevant to this repo. Sources are Ansible's own docs plus Apple
developer/support docs, fetched live; gaps are flagged rather than filled by assumption.

- **`user`/`group` on macOS use `dscl`, not `useradd`/`groupadd`.** Verbatim from Ansible's docs:
  *"On macOS, this module uses `dscl` to create, modify, and delete accounts. `dseditgroup` is used
  to modify group membership."* Password handling also differs: macOS requires a **cleartext**
  password via the module's `password` option (not a pre-hashed value as on Linux) — *"the password
  specified in the `password` option will always be set, regardless of whether the user account
  already exists."* Default primary group on macOS is `staff`; default shell for non-system users
  is `/bin/bash` (Ansible ≥ 2.5; `/usr/bin/false` before that); `comment`/GECOS defaults to `name`.
- **The "UID 500 boundary" is real historical macOS behavior but is not documented anywhere in
  Apple's current docs.** Apple's live account-hiding guidance
  (https://support.apple.com/en-us/102099) uses the `dscl` `IsHidden` attribute
  (`dscl . create /Users/x IsHidden 1`), with no mention of UID thresholds. The classic "human
  accounts start at 501" convention (via the old `Hide500Users` loginwindow key) is legacy/
  community knowledge, not an Apple-cited rule — worth knowing this repo's schema
  (`uid: 501-999`) is following a convention Apple itself no longer documents, not a hard
  requirement it enforces.
- **Python interpreter discovery**: `ansible_python_interpreter` overrides Ansible's `auto`
  (default) discovery. Ansible's own interpreter-discovery docs contain **no macOS/Darwin-specific
  wording at all** — no mention of SIP, Homebrew's `/opt/homebrew` vs `/usr/local`, or Catalina
  removing `/usr/bin/python2`. Any macOS-specific interpreter guidance beyond the generic mechanism
  is inference, not something Ansible states.
- **System Integrity Protection (SIP)**: per Apple, SIP "restricts the root user account" and
  protects `/System`, `/usr`, `/bin`, `/sbin`, `/var` — only Apple-signed processes with special
  entitlements can write there, even as root. `/usr/local`, `/Applications`, `/Library` remain
  writable. (https://support.apple.com/en-us/102149)
- **setgid on directories — macOS/BSD semantics differ from Linux.** Apple's own developer docs
  define it plainly: *"The GID of any file or directory created within the directory is set to the
  GID of the directory."* Separately (multiple corroborating technical sources, not an Apple
  primary source): BSD-derived filesystems including macOS's behave as if setgid inheritance is
  effectively always on for new files in a directory, whereas Linux only does this when the bit is
  explicitly set — otherwise Linux uses the creating process's effective GID. This repo's
  `shared_surface` role setting `mode: "2775"` is being explicit about something macOS mostly does
  by default anyway, which is harmless and keeps the intent visible in code.
- **POSIX ACLs on macOS use a completely different mechanism than Linux**: `chmod +a`/`chmod -a`
  with NFSv4-style ACEs (e.g. `chmod +a "admin allow read,readattr,readextattr,readsecurity"
  MyDir`), layered on top of the three standard rwx bits — not POSIX.1e ACLs, and **not**
  manageable via `ansible.posix.acl` (macOS ships neither `setfacl` nor `getfacl`). Any future
  fine-grained permission need on macOS in this repo would have to shell out to `chmod +a`
  directly via `command`/`shell`, not the ACL module.
- **Extended attributes / quarantine**: `com.apple.quarantine` is the xattr Gatekeeper sets on
  internet-downloaded files (`xattr -d com.apple.quarantine <path>` removes it). Apple's own
  developer-forum guidance notes this attribute "is not considered API."
- **TCC / Full Disk Access**: confirmed separately from SIP — macOS 10.15+ requires explicit user
  consent (or a granted Full Disk Access entitlement in System Settings) before any app can access
  Desktop/Documents/Downloads/iCloud Drive/network-volume content, layered on top of SIP.
  **Unresolved gap**: Apple's own security guide does not explicitly state whether root/privileged
  automation is exempt from TCC prompts for these folders — this was not verifiable from a primary
  Apple source, and should be tested directly rather than assumed if this repo's `shared_surface`
  role is ever pointed at a TCC-protected location instead of `/Users/Shared/workspace`.
- **Adjacent macOS collection modules** (not used by this repo, noted for completeness):
  `community.general.homebrew` / `homebrew_cask` / `homebrew_tap`, and
  `community.general.osx_defaults` (not `macos_defaults`) for preference plists. No
  `community.general` module exists for macOS account or ACL management beyond what's covered
  above.

## 5. Configuration, Idempotency & Project Layout

Source: [config.html](https://docs.ansible.com/ansible/latest/reference_appendices/config.html), [general_precedence.html](https://docs.ansible.com/projects/ansible/latest/reference_appendices/general_precedence.html), [glossary.html](https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html), [sample_setup.html](https://docs.ansible.com/ansible/latest/tips_tricks/sample_setup.html)

- **`ansible.cfg` lookup order**, first found wins: `ANSIBLE_CONFIG` env var → `ansible.cfg` in the
  current directory → `~/.ansible.cfg` → `/etc/ansible/ansible.cfg`. Broader precedence: config
  settings → command-line options → playbook keywords → variables → direct assignment.
  `ANSIBLE_*` env vars override whichever `ansible.cfg` file was actually loaded.
- **Idempotency**, Ansible's own glossary definition: *"An operation is idempotent if the result of
  performing it once is exactly the same as the result of performing it repeatedly without any
  intervening actions."* Not all modules support check mode; conditionals on registered variables
  may not populate correctly under `--check`.
- **Collections vs. roles**: a role is one reusable unit (tasks/handlers/vars/etc., auto-loaded by
  filename convention) for one purpose; a **collection** is the larger packaging/distribution
  format that can bundle multiple roles plus modules and plugins, with `galaxy.yml` as its required
  root metadata file — this repo ships as the `thruput.local_runtime` collection.
- **Sample directory layout** from Ansible's own docs: per-environment inventory files (e.g.
  `production`, `staging`), `group_vars/`, `host_vars/`, a `site.yml` master playbook, and
  `roles/`. For larger environments, full separation via `inventories/production/`,
  `inventories/staging/` (each with its own inventory + `group_vars`/`host_vars`). The docs are
  explicit that this layout isn't prescriptive: *"Your usage of Ansible should fit your needs, so
  feel free to modify this approach."*
