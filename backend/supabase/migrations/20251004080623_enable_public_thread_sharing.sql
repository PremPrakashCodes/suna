-- Migration to enable public thread sharing without authentication
-- This updates RLS policies to check thread.is_public in addition to project.is_public
-- Note: thread_select_policy was already updated in migration 20250504123828_fix_thread_select_policy.sql
-- This migration updates message_select_policy and agent_run_select_policy to be consistent

BEGIN;

-- Drop existing policies that need to be updated
DROP POLICY IF EXISTS message_select_policy ON messages;
DROP POLICY IF EXISTS agent_run_select_policy ON agent_runs;

-- Update message select policy to check thread.is_public
CREATE POLICY message_select_policy ON messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM threads
            LEFT JOIN projects ON threads.project_id = projects.project_id
            WHERE threads.thread_id = messages.thread_id
            AND (
                threads.is_public IS TRUE OR
                projects.is_public IS TRUE OR
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
                threads.is_public IS TRUE OR
                projects.is_public IS TRUE OR
                basejump.has_role_on_account(threads.account_id) = true OR 
                basejump.has_role_on_account(projects.account_id) = true
            )
        )
    );

COMMIT;
