---
- name: Schedule a task to minimize all windows every minute
  hosts: windows_servers
  gather_facts: false

  vars:
    task_name: "MinimizeWindowsEveryMinute"
    # Пользователь, от имени которого будет выполняться задача (должен иметь активную сессию)
    task_user: "{{ ansible_user }}"
    task_password: "{{ ansible_password }}"

  tasks:
    - name: Create scheduled task to minimize windows every minute
      ansible.windows.win_scheduled_task:
        name: "{{ task_name }}"
        description: "Minimizes all open windows every minute"
        actions:
          - path: powershell.exe
            arguments: "-Command \"(New-Object -ComObject Shell.Application).MinimizeAll()\""
        triggers:
          - type: time
            repetition:
              interval: "PT1M"   # Каждую минуту (ISO 8601 duration)
              duration: "P1D"    # Действует бесконечно (повторять в течение дня)
              stop_at_duration_end: false
            start_boundary: "{{ ansible_date_time.iso8601 }}"  # Начать сейчас
        user: "{{ task_user }}"
        password: "{{ task_password }}"
        state: present
        enabled: yes
        run_level: highest   # Запуск с наивысшими правами (если нужно)
      register: task_creation

    - name: Run the task immediately once to test
      ansible.windows.win_shell: |
        Start-ScheduledTask -TaskName "{{ task_name }}"
      when: task_creation.changed
      ignore_errors: yes