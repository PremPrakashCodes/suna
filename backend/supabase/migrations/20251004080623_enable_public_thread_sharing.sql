-- Migration to enable public thread sharing without authentication
-- This updates RLS policies to check thread.is_public in addition to project.is_public

BEGIN;

-- Drop existing policies that need to be updated
DROP POLICY IF EXISTS thread_select_policy ON threads;
DROP POLICY IF EXISTS message_select_policy ON messages;
DROP POLICY IF EXISTS agent_run_select_policy ON agent_runs;

-- Update thread select policy to check thread.is_public
CREATE POLICY thread_select_policy ON threads
    FOR SELECT
    USING (
        threads.is_public = TRUE OR
        basejump.has_role_on_account(account_id) = true OR 
        EXISTS (
            SELECT 1 FROM projects
            WHERE projects.project_id = threads.project_id
            AND (
                projects.is_public = TRUE OR
                basejump.has_role_on_account(projects.account_id) = true
            )
        )
    );

-- Update message select policy to check thread.is_public
CREATE POLICY message_select_policy ON messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM threads
            LEFT JOIN projects ON threads.project_id = projects.project_id
            WHERE threads.thread_id = messages.thread_id
            AND (
                threads.is_public = TRUE OR
                projects.is_public = TRUE OR
                basejump.has_role_on_account(threads.account_id) = true OR 
                basejump.has_role_on_account(projects.account_id) = true
            )
        )
    );

-- Update agent_run select policy to check thread.is_public
CREATE POLICY agent_run_select_policy ON agent_runs
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM threads
            LEFT JOIN projects ON threads.project_id = projects.project_id
            WHERE threads.thread_id = agent_runs.thread_id
            AND (
                threads.is_public = TRUE OR
                projects.is_public = TRUE OR
                basejump.has_role_on_account(threads.account_id) = true OR 
                basejump.has_role_on_account(projects.account_id) = true
            )
        )
    );

COMMIT;
