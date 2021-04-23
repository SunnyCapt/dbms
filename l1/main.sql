create or replace procedure versions_info is
    cursor version_info is
        -- get current version
        select null as action_time, null as action, null as comments, version
        from v$instance
        union
        -- get version's changing history
        select action_time, action, comments, version
        from dba_registry_history where action = 'UPGRADE' --or action = 'APPLY'
        order by action_time;
    previus_version varchar2(64);
    current_version varchar2(64);
    body            varchar2(32767) := '';
    buff            varchar2(1024);
    iterator        Number := 1;
begin
    for v_raw in version_info
        -- build table body
        loop
            if v_raw.action_time is null then
                -- specify the got current_version
                current_version := v_raw.version;
            else
                -- noinspection SqlSignature
                if previus_version is null then
                    previus_version := regexp_replace(v_raw.comments, '[^[:digit:].]');
                end if;
                buff := to_char(iterator) || '   ' || to_char(v_raw.action_time, 'dd.mm.yyyy')
                    || chr(9) || chr(9) || previus_version || chr(9) || chr(9) || chr(9)|| chr(9) || v_raw.version || chr(10);

                body := body || buff;
                previus_version := v_raw.version;
                iterator := iterator + 1;
            end if;
        end loop;

    if iterator > 1 then
        -- if there were updates, then display the collected information
        buff := 'Текущая версия СУБД: ' || current_version || chr(10) || chr(10)
            || 'No. Дата обновления	Версия до обновления	Версия после обновления' || chr(10)
            || '--- -----------------	----------------------	------------------------' || chr(10);
        dbms_output.put_line(buff || body);
    else
        -- otherwise report that there were no updates
        dbms_output.put_line('Отсутствует информация об обновлениях Oracle');
    end if;
end;

call versions_info();