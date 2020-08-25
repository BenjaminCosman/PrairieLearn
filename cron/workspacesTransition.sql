-- BLOCK select_nonterminated_or_nonterminating_workspace_hosts
SELECT
    wh.id,
    wh.instance_id,
    wh.load_count,
    wh.hostname
FROM
    workspace_hosts AS wh
WHERE
    wh.state NOT IN ('terminated', 'terminating');

-- BLOCK select_running_or_terminating_workspace_hosts
SELECT
    wh.id,
    wh.instance_id,
    wh.load_count,
    wh.hostname
FROM
    workspace_hosts AS wh
WHERE
    wh.state != 'terminated';

-- BLOCK select_healthy_hosts
SELECT
    wh.id,
    wh.instance_id,
    wh.load_count,
    wh.hostname
FROM
    workspace_hosts AS wh
WHERE
    wh.state = 'ready' OR
    wh.state = 'draining';

-- BLOCK set_host_unhealthy
UPDATE workspace_hosts
SET
    state = 'unhealthy',
    unhealthy_at = NOW()
WHERE
    instance_id = $instance_id
    AND unhealthy_at IS NULL;

-- BLOCK add_terminating_hosts
INSERT INTO workspace_hosts
    (state, state_changed_at, instance_id)
    (SELECT 'terminating', NOW(), UNNEST($instances))
ON CONFLICT (instance_id) DO UPDATE SET
    state = EXCLUDED.state,
    state_changed_at = EXCLUDED.state_changed_at;

-- BLOCK set_terminated_hosts_if_not_launching
UPDATE workspace_hosts AS wh
SET state='terminated',
    terminated_at = NOW()
WHERE instance_id IN (SELECT UNNEST($instances)) AND wh.state != 'launching';
