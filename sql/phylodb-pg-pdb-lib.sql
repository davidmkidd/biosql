
-- $Id$
--
-- Copyright 2006-2008 Hilmar Lapp, William Piel
--           2010-2011 David Kidd
--  This file is part of BioSQL.
--
--  BioSQL is free software: you can redistribute it and/or modify it
--  under the terms of the GNU Lesser General Public License as
--  published by the Free Software Foundation, either version 3 of the
--  License, or (at your option) any later version.
--
--  BioSQL is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU Lesser General Public License for more details.
--
--  You should have received a copy of the GNU Lesser General Public License
--  along with BioSQL. If not, see <http://www.gnu.org/licenses/>.
--
-- ========================================================================
--
-- 
-- phylodb-pg-pdb-lib.sql
-- ======================
--
-- A PostgeSQL library of functions for the PhyloDB extension to SQL.
-- 
-- Includes function implementations of queries described in https://github.com/hlapp/biosql/blob/master/sql/phylodb-topo-queries.sql
-- 
-- See phylodb-pg-pdb-lib.pdf for further information.
--
-- Authors: Hilmar Lapp, David Kidd
--
-- comments to biosql - biosql-l@open-bio.org

SET search_path = biosql, pg_catalog;

--
-- Name: pdb_as_newick(integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_as_newick(val integer) RETURNS text
    LANGUAGE plpgsql
    AS $$

	-- Returns newick string of subtree defined by node

	DECLARE
	  arg INTEGER;
	  str TEXT;
	  child INTEGER;
	  n INTEGER;
	  nc INTEGER;
	BEGIN

	  arg := val;

	  IF arg IS NULL OR arg < 0 THEN
	    BEGIN
	      RAISE NOTICE 'Invalid Input';
	      RETURN NULL;
	    END;
	  ELSE
	    BEGIN
	      str := '(';
              SELECT INTO n COUNT(*) FROM biosql.pdb_node_children(arg);
	      IF n > 0 THEN 
		str := str  || '(';
		FOR child IN SELECT biosql.pdb_node_children(arg)
	          LOOP
                  SELECT INTO nc COUNT(*) FROM biosql.pdb_node_children(child);
	          IF nc = 0 THEN 
	            str := str || '''' || child || ''',';
	          ELSE
	            str := str || biosql.pdb_as_newick(child) || ',';
	          END IF;
	          END LOOP;
	        str := TRIM(TRAILING ',' FROM str);
	        str := str || ')';
	      END IF;
	      str := str || '''' || arg || ''');';
	      RETURN str;
	    END;
	  END IF;
	END;

	$$;


ALTER FUNCTION biosql.pdb_as_newick(val integer) OWNER TO postgres;

--
-- Name: pdb_as_newick(integer, text, boolean); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_as_newick(node_id integer, attrib text, rootdepth boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$

	-- Returns newick string of subtree defined by node

	DECLARE

	  str TEXT;
	  child INTEGER;
	  n INTEGER;
	  nc INTEGER;
	  dist NUMERIC;
	  label TEXT;
	BEGIN

	  IF node_id IS NULL OR node_id < 0 THEN
	    BEGIN
	      RAISE NOTICE 'Invalid Input';
	      RETURN NULL;
	    END;
	  ELSE
	    BEGIN
	      dist := biosql.pdb_node_qualifier(node_id, attrib);
	      str := '(';
              SELECT INTO n COUNT(*) FROM biosql.pdb_node_children(node_id);
	      IF n > 0 THEN 
		str := str  || '(';
		FOR child IN SELECT biosql.pdb_node_children(node_id)
	          LOOP
                  SELECT INTO nc COUNT(*) FROM biosql.pdb_node_children(child);
	          IF nc = 0 THEN 
	            str := str || '''' || child || ''':' || dist || ',';
	          ELSE
	            str := str || biosql.pdb_as_newick(child, attrib, TRUE) || ',';
	          END IF;
	          END LOOP;
	        str := TRIM(TRAILING ',' FROM str);
	        str := str || ')';
	      END IF;
	      IF rootdepth = true THEN
	        str := str || '''' || node_id || ''':' || dist || ')';
	      ELSE
		str := str || '''' || node_id || ''');';
	      END IF;
	      RETURN str;
	    END;
	  END IF;
	END;

	$$;


ALTER FUNCTION biosql.pdb_as_newick(node_id integer, attrib text, rootdepth boolean) OWNER TO postgres;

--
-- Name: pdb_as_newick_label(integer, text, text, boolean); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_as_newick_label(tree integer, label text, attrib text, rootdepth boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$

	-- Returns newick string of subtree defined by node

	DECLARE
	  id INTEGER;
	  dist NUMERIC;
	  str TEXT;
	  child_id INTEGER;
	  child_lab TEXT;
	  child_dist NUMERIC;
	  n INTEGER;
	  nc INTEGER;

	BEGIN
	  --check if in tree
	  SELECT INTO id biosql.pdb_node_label_to_id(tree,label);
	  dist := biosql.pdb_node_qualifier(id, attrib);
	  
	  IF id IS NULL THEN
	    BEGIN
	      RAISE NOTICE 'Label not in tree';
	      RETURN NULL;
	    END;
	  ELSE
	    BEGIN
	      str := '(';
              SELECT INTO n COUNT(*) FROM biosql.pdb_node_children(id);
	      IF n > 0 THEN 
		str := str  || '(';
		FOR child_id IN SELECT biosql.pdb_node_children(id)
	          LOOP
	          child_lab := biosql.pdb_node_id_to_label(child_id);
	          child_dist := biosql.pdb_node_qualifier(child_id,attrib);
                  SELECT INTO nc COUNT(*) FROM biosql.pdb_node_children(child_id);
	          IF nc = 0 THEN 
	            str := str || '''' || replace(child_lab, ' ', '_') || ''':' || child_dist || ',';
	          ELSE
	            str := str || biosql.pdb_as_newick_label(tree, child_lab::text, attrib, true) || ',';
	          END IF;
	          END LOOP;
	        str := TRIM(TRAILING ',' FROM str);
	        str := str || ')';
	      END IF;
	      IF rootdepth = true THEN
	        str := str || '''' || replace(label, ' ', '_') || ''':' || dist || ')';
	      ELSE
		str := str || '''' || replace(label, ' ', '_') || ''');';
	      END IF;
	      RETURN str;
	    END;
	  END IF;
	END;

	$$;


ALTER FUNCTION biosql.pdb_as_newick_label(tree integer, label text, attrib text, rootdepth boolean) OWNER TO postgres;

--
-- Name: pdb_as_newick_label(integer, text); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_as_newick_label(tree integer, label text) RETURNS text
    LANGUAGE plpgsql
    AS $$

	-- Returns newick string of subtree defined by node

	DECLARE
	  id INTEGER;
	  dist NUMERIC;
	  str TEXT;
	  child_id INTEGER;
	  child_lab TEXT;
	  child_dist NUMERIC;
	  n INTEGER;
	  nc INTEGER;

	BEGIN
	  --check if in tree
	  SELECT INTO id biosql.pdb_node_label_to_id(tree,label);
	  --dist := biosql.pdb_node_qualifier(id, attrib);
	  
	  IF id IS NULL THEN
	    BEGIN
	      RAISE NOTICE 'Label not in tree';
	      RETURN NULL;
	    END;
	  ELSE
	    BEGIN
	      str := '(';
              SELECT INTO n COUNT(*) FROM biosql.pdb_node_children(id);
	      IF n > 0 THEN 
		str := str  || '(';
		FOR child_id IN SELECT biosql.pdb_node_children(id)
	          LOOP
	          child_lab := biosql.pdb_node_id_to_label(child_id);
	          --child_dist := biosql.pdb_node_qualifier(child_id,attrib);
                  SELECT INTO nc COUNT(*) FROM biosql.pdb_node_children(child_id);
	          IF nc = 0 THEN 
	            str := str || '''' || replace(child_lab, ' ', '_') || ''',';
	          ELSE
	            str := str || biosql.pdb_as_newick_label(tree, child_lab::text) || ',';
	          END IF;
	          END LOOP;
	        str := TRIM(TRAILING ',' FROM str);
	        str := str || ')';
	      END IF;
	      str := str || '''' || replace(label, ' ', '_') || ''')';
	      RETURN str;
	    END;
	  END IF;
	END;

	$$;


ALTER FUNCTION biosql.pdb_as_newick_label(tree integer, label text) OWNER TO postgres;

--
-- Name: pdb_lca(integer, integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca(integer, integer) RETURNS integer
    LANGUAGE sql
    AS $_$
	
	SELECT lca.node_id
	FROM biosql.node lca, biosql.node_path pA, biosql.node_path pB
	WHERE pA.parent_node_id = pB.parent_node_id
	AND lca.node_id = pA.parent_node_id
	AND pA.child_node_id = $1
	AND pB.child_node_id = $2
	AND biosql.pdb_node_tree($1) = biosql.pdb_node_tree($2)
	ORDER BY pA.distance
	LIMIT 1;$_$;


ALTER FUNCTION biosql.pdb_lca(integer, integer) OWNER TO postgres;

--
-- Name: pdb_lca(integer, integer[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca(tree_id integer, arr integer[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$

	DECLARE
	min_idx INTEGER;
	max_idx INTEGER;
	lca INTEGER;


	BEGIN
	IF biosql.pdb_node_in_tree(tree_id, arr) = FALSE THEN
	  RETURN NULL;
	ELSE
	  BEGIN
	  SELECT INTO min_idx MIN(n.left_idx) FROM biosql.node n WHERE n.node_id = ANY(arr);
	  SELECT INTO max_idx MAX(n.right_idx) FROM biosql.node n WHERE n.node_id = ANY(arr);

	  SELECT INTO lca n.node_id
	    FROM biosql.node n
	    WHERE n.left_idx <= min_idx
	    AND n.right_idx >= max_idx
	    AND n.tree_id = tree_id
	    ORDER BY n.right_idx - n.left_idx ASC
	    LIMIT 1;

	    RETURN lca;
	  END;
	END IF;
	END;
	
	$$;


ALTER FUNCTION biosql.pdb_lca(tree_id integer, arr integer[]) OWNER TO postgres;

--
-- Name: pdb_lca(integer, text, text); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca(integer, text, text) RETURNS integer
    LANGUAGE sql
    AS $_$
	-- $1	node A
	-- $2	node B
	-- $3   tree id
	SELECT n.node_id
	FROM biosql.node n, biosql.node_path pA, biosql.node_path pB
	WHERE pA.parent_node_id = pB.parent_node_id
	AND   n.node_id = pA.parent_node_id
	AND   pA.child_node_id IN (SELECT biosql.pdb_label_to_id($1,$2))
	AND   pB.child_node_id IN (SELECT biosql.pdb_label_to_id($1,$3))
	AND   n.tree_id = $1
	ORDER BY pA.distance
	LIMIT 1;
	$_$;


ALTER FUNCTION biosql.pdb_lca(integer, text, text) OWNER TO postgres;

--
-- Name: pdb_lca(integer, text[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca(integer, text[]) RETURNS integer
    LANGUAGE plpgsql
    AS $_$

	DECLARE
	min_idx INTEGER;
	max_idx INTEGER;
	lca INTEGER;

	BEGIN
	SELECT INTO min_idx MIN(n.left_idx) FROM biosql.node n WHERE n.label = ANY($2) AND n.tree_id = $1;
	SELECT INTO max_idx MAX(n.right_idx) FROM biosql.node n WHERE n.label = ANY($2) AND n.tree_id = $1;

	SELECT INTO lca n.node_id
	FROM biosql.node n
	WHERE n.left_idx <= min_idx
	AND   n.right_idx >= max_idx
	ORDER BY n.right_idx - n.left_idx ASC
	LIMIT 1;

	RETURN lca;
	END;
	$_$;


ALTER FUNCTION biosql.pdb_lca(integer, text[]) OWNER TO postgres;

--
-- Name: pdb_lca_a_exclude_b(integer, integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_a_exclude_b(integer, integer) RETURNS integer
    LANGUAGE sql
    AS $_$

	SELECT dca.node_id
	FROM biosql.node dca, biosql.node_path pA
	WHERE
	     dca.node_id = pA.parent_node_id
	AND  pA.child_node_id = $1
	AND NOT EXISTS (
	       SELECT 1 FROM biosql.node_path pB
	       WHERE pB.parent_node_id = pA.parent_node_id
	       AND   pB.child_node_id = $2
	)
	ORDER BY pA.distance DESC
	LIMIT 1;
	$_$;


ALTER FUNCTION biosql.pdb_lca_a_exclude_b(integer, integer) OWNER TO postgres;

--
-- Name: pdb_lca_subtree(integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_subtree(integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
	
	SELECT p.child_node_id
	FROM biosql.node_path p
	WHERE p.parent_node_id = $1
	UNION
	SELECT $1
	$_$;


ALTER FUNCTION biosql.pdb_lca_subtree(integer) OWNER TO postgres;

--
-- Name: pdb_lca_subtree(integer[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_subtree(integer[]) RETURNS SETOF integer
    LANGUAGE plpgsql
    AS $_$

	DECLARE
		mylca 	INTEGER;
		mynode	INTEGER;

	BEGIN
		SELECT INTO mylca biosql.pdb_lca($1);
	
		FOR mynode IN
		
			SELECT p.child_node_id as lca
			FROM biosql.node_path p
			WHERE p.parent_node_id = mylca
			UNION
			SELECT mylca

		LOOP
		RETURN NEXT mynode;
		END LOOP;
	END;
	$_$;


ALTER FUNCTION biosql.pdb_lca_subtree(integer[]) OWNER TO postgres;

--
-- Name: pdb_lca_subtree(integer, text[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_subtree(integer, text[]) RETURNS SETOF integer
    LANGUAGE plpgsql
    AS $_$

	DECLARE
		mylca 	INTEGER;
		mynode	INTEGER;

	BEGIN
		SELECT INTO mylca biosql.pdb_lca($1,$2);
	
		FOR mynode IN
		
			SELECT p.child_node_id as lca
			FROM biosql.node_path p
			WHERE p.parent_node_id = mylca
			UNION
			SELECT biosql.lca($1,$2)

		LOOP
		RETURN NEXT mynode;
		END LOOP;
	END;
	$_$;


ALTER FUNCTION biosql.pdb_lca_subtree(integer, text[]) OWNER TO postgres;

--
-- Name: pdb_lca_subtree_edge(integer, integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_subtree_edge(integer, integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
	SELECT e.edge_id 
	FROM biosql.node_path p, biosql.edge e, biosql.node pt, biosql.node ch 
	WHERE 
	    e.child_node_id = p.child_node_id
	AND pt.node_id = e.parent_node_id
	AND ch.node_id = e.child_node_id
	AND pt.tree_id = ch.tree_id
	AND p.parent_node_id IN (
	      SELECT pA.parent_node_id
	      FROM   biosql.node_path pA, biosql.node_path pB
	      WHERE pA.parent_node_id = pB.parent_node_id
	      AND   pA.child_node_id = $1 
	      AND   pB.child_node_id = $2
	      ORDER BY pA.distance
	      LIMIT 1
	)$_$;


ALTER FUNCTION biosql.pdb_lca_subtree_edge(integer, integer) OWNER TO postgres;

--
-- Name: pdb_lca_subtree_edge(integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_subtree_edge(integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
	SELECT e.edge_id 
	FROM biosql.node_path p, biosql.edge e, biosql.node pt, biosql.node ch 
	WHERE 
	    e.child_node_id = p.child_node_id
	AND pt.node_id = e.parent_node_id
	AND ch.node_id = e.child_node_id
	AND p.parent_node_id = $1
$_$;


ALTER FUNCTION biosql.pdb_lca_subtree_edge(integer) OWNER TO postgres;

--
-- Name: pdb_lca_subtree_edge(integer, text[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_subtree_edge(integer, text[]) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
	SELECT e.edge_id 
	FROM biosql.node_path p, biosql.edge e, biosql.node pt, biosql.node ch 
	WHERE 
	    e.child_node_id = p.child_node_id
	AND pt.node_id = e.parent_node_id
	AND ch.node_id = e.child_node_id
	AND p.parent_node_id = biosql.pdb_lca($1,$2)
	$_$;


ALTER FUNCTION biosql.pdb_lca_subtree_edge(integer, text[]) OWNER TO postgres;

--
-- Name: pdb_lca_subtree_edge(integer, integer[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_subtree_edge(tree_id integer, nodes integer[]) RETURNS SETOF integer
    LANGUAGE plpgsql
    AS $$

	DECLARE
		--myedge 		biosql.edge.edge_id%TYPE;
		myedge		INTEGER;
		mylca 		INTEGER;
		lca_left	INTEGER;
		lca_right	INTEGER;

	BEGIN
	  IF biosql.pdb_node_in_tree(tree_id, nodes) = FALSE THEN
		RETURN NEXT NULL;
	  ELSE
		SELECT INTO mylca biosql.pdb_lca(tree_id, nodes);
		SELECT INTO lca_left n.left_idx FROM biosql.node n WHERE n.node_id = mylca;
		SELECT INTO lca_right n.right_idx FROM biosql.node n WHERE n.node_id = mylca;

		FOR myedge IN
		SELECT e.edge_id
		FROM biosql.node_path np, biosql.edge e
		WHERE np.parent_node_id = mylca
		AND np.child_node_id = e.child_node_id
		AND np.child_node_id IN (SELECT n.node_id 
			FROM biosql.node n
			WHERE n.left_idx BETWEEN lca_left AND lca_right)
		LOOP
		RETURN NEXT myedge;
		END LOOP;
	  END IF;
	END
	$$;


ALTER FUNCTION biosql.pdb_lca_subtree_edge(tree_id integer, nodes integer[]) OWNER TO postgres;

--
-- Name: pdb_lca_subtree_internal(integer, text[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_subtree_internal(integer, text[]) RETURNS SETOF integer
    LANGUAGE plpgsql
    AS $_$

	DECLARE
		mylca 	INTEGER;
		mynodes	INTEGER;

	BEGIN
		SELECT INTO mylca biosql.pdb_lca($1,$2);
	
		FOR mynodes IN
		
			SELECT p.child_node_id
			FROM biosql.node_path p, biosql.node n
			WHERE p.parent_node_id = mylca
			AND n.node_id = p.child_node_id
			AND (n.right_idx - n.left_idx) != 1
			UNION
			SELECT biosql.pdb_lca($1,$2)

		LOOP
		RETURN NEXT mynodes;
		END LOOP;
	END;
	$_$;


ALTER FUNCTION biosql.pdb_lca_subtree_internal(integer, text[]) OWNER TO postgres;

--
-- Name: pdb_lca_subtree_internal_label(integer, text[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_subtree_internal_label(integer, text[]) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$

	DECLARE
		mylca 	INTEGER;
		mylab	TEXT;

	BEGIN
		SELECT INTO mylca biosql.pdb_lca($1,$2);
	
		FOR mylab IN
		
			SELECT n.label
			FROM biosql.node_path p, biosql.node n
			WHERE p.parent_node_id = mylca
			AND n.left_idx <> n.right_idx - 1
			AND n.node_id = p.child_node_id
			

		LOOP
		RETURN NEXT mylab;
		END LOOP;
	END;
	$_$;


ALTER FUNCTION biosql.pdb_lca_subtree_internal_label(integer, text[]) OWNER TO postgres;

--
-- Name: pdb_lca_subtree_label(integer, text[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_subtree_label(integer, text[]) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$

	DECLARE
		mylca 	INTEGER;
		mynode	INTEGER;

	BEGIN
		SELECT INTO mylca biosql.pdb_lca($1,$2);
	
		FOR mynode IN
		
			SELECT p.child_node_id as lca
			FROM biosql.node_path p
			WHERE p.parent_node_id = mylca
			UNION
			SELECT biosql.lca($1,$2)

		LOOP
		RETURN NEXT biosql.id_to_label(mynode);
		END LOOP;
	END;
	$_$;


ALTER FUNCTION biosql.pdb_lca_subtree_label(integer, text[]) OWNER TO postgres;

--
-- Name: pdb_lca_subtree_tip(integer, text[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_subtree_tip(integer, text[]) RETURNS SETOF integer
    LANGUAGE plpgsql
    AS $_$

	DECLARE
		mylca 	INTEGER;
		mynodes	INTEGER;

	BEGIN
		SELECT INTO mylca biosql.pdb_lca($1,$2);
	
		FOR mynodes IN
		
			SELECT p.child_node_id
			FROM biosql.node_path p, biosql.node n
			WHERE p.parent_node_id = mylca
			AND (n.right_idx - n.left_idx) = 1
			AND n.node_id = p.child_node_id
			

		LOOP
		RETURN NEXT mynodes;
		END LOOP;
	END;
	$_$;


ALTER FUNCTION biosql.pdb_lca_subtree_tip(integer, text[]) OWNER TO postgres;

--
-- Name: pdb_lca_subtree_tip_label(integer, text[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_lca_subtree_tip_label(integer, text[]) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$

	DECLARE
		mylca 	INTEGER;
		mylab	TEXT;

	BEGIN
		SELECT INTO mylca biosql.pdb_lca($1,$2);
	
		FOR mylab IN
		
			SELECT n.label
			FROM biosql.node_path p, biosql.node n
			WHERE p.parent_node_id = mylca
			AND (n.right_idx - n.left_idx) = 1
			AND n.node_id = p.child_node_id
			

		LOOP
		RETURN NEXT mylab;
		END LOOP;
	END;
	$_$;


ALTER FUNCTION biosql.pdb_lca_subtree_tip_label(integer, text[]) OWNER TO postgres;

--
-- Name: pdb_node_children(integer, integer[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_children(integer, integer[]) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
	
	SELECT np.child_node_id
	FROM biosql.node_path np
	WHERE np.parent_node_id = $1
	AND np.child_node_id = ANY($2)
	AND np.distance = 1;
$_$;


ALTER FUNCTION biosql.pdb_node_children(integer, integer[]) OWNER TO postgres;

--
-- Name: pdb_node_children(integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_children(integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
	
	SELECT np.child_node_id
	FROM biosql.node_path np
	WHERE np.parent_node_id = $1
	AND np.distance = 1;
$_$;


ALTER FUNCTION biosql.pdb_node_children(integer) OWNER TO postgres;

--
-- Name: pdb_node_children_dist(integer, text, text); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_children_dist(integer, text, text) RETURNS SETOF pdb_node_children_dist_type
    LANGUAGE sql
    AS $_$

	  SELECT e.child_node_id, nc.label, eq.value::numeric
	  FROM biosql.node np,
	  biosql.node nc,
	  biosql.edge e,
	  biosql.edge_qualifier_value eq,
	  biosql.term t
	  WHERE eq.term_id = t.term_id
	  AND e.edge_id = eq.edge_id
	  AND e.parent_node_id = np.node_id
	  AND e.child_node_id = nc.node_id
	  AND t.name = $3
	  AND e.parent_node_id = biosql.pdb_node_label_to_id($1, $2)

	
$_$;


ALTER FUNCTION biosql.pdb_node_children_dist(integer, text, text) OWNER TO postgres;

--
-- Name: pdb_node_id_to_label(integer[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_id_to_label(integer[]) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
	--$1 node id
	SELECT n.label
	FROM biosql.node n
	WHERE n.node_id = ANY($1)
	ORDER BY n.node_id;
$_$;


ALTER FUNCTION biosql.pdb_node_id_to_label(integer[]) OWNER TO postgres;

--
-- Name: pdb_node_id_to_label(integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_id_to_label(integer) RETURNS text
    LANGUAGE sql
    AS $_$
	
	SELECT n.label
	FROM biosql.node n
	WHERE n.node_id = $1
	ORDER BY n.node_id
	LIMIT 1;
$_$;


ALTER FUNCTION biosql.pdb_node_id_to_label(integer) OWNER TO postgres;

--
-- Name: pdb_node_in_tree(integer, integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_in_tree(integer, integer) RETURNS boolean
    LANGUAGE sql
    AS $_$
	SELECT
	CAST((CASE WHEN COUNT(n.node_id) = 0 THEN FALSE ELSE TRUE END) AS BOOLEAN) AS IsTip
	FROM biosql.node n
	WHERE n.node_id = $2
	AND n.tree_id = $1;
$_$;


ALTER FUNCTION biosql.pdb_node_in_tree(integer, integer) OWNER TO postgres;

--
-- Name: pdb_node_in_tree(integer, integer[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_in_tree(integer, integer[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
	SELECT
	CAST((CASE WHEN COUNT(n.node_id) <> array_upper($2, 1) THEN FALSE ELSE TRUE END) AS BOOLEAN) AS IsTip
	FROM biosql.node n
	WHERE n.node_id = ANY($2)
	AND n.tree_id = $1;
$_$;


ALTER FUNCTION biosql.pdb_node_in_tree(integer, integer[]) OWNER TO postgres;

--
-- Name: pdb_node_istip(integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_istip(integer) RETURNS boolean
    LANGUAGE sql
    AS $_$


	SELECT
	CAST((CASE WHEN n.node_id IS NULL THEN FALSE ELSE TRUE END) AS BOOLEAN) AS IsTip
	FROM biosql.node n
	WHERE n.node_id = $1
	AND n.left_idx = (n.right_idx - 1)
	;
$_$;


ALTER FUNCTION biosql.pdb_node_istip(integer) OWNER TO postgres;

--
-- Name: pdb_node_istip(integer, text); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_istip(integer, text) RETURNS boolean
    LANGUAGE sql
    AS $_$

	SELECT
	CAST((CASE WHEN n.node_id IS NULL THEN FALSE ELSE TRUE END) AS BOOLEAN) AS IsTip
	FROM biosql.node n
	WHERE n.label = $2
	AND n.tree_id = $1
	AND n.left_idx = (n.right_idx - 1)
	;
$_$;


ALTER FUNCTION biosql.pdb_node_istip(integer, text) OWNER TO postgres;

--
-- Name: pdb_node_label_to_id(integer, text); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_label_to_id(integer, text) RETURNS integer
    LANGUAGE sql
    AS $_$
	--$1 node label
	--$2 tree id	
	SELECT n.node_id
	FROM biosql.node n
	WHERE n.label = $2
	AND   n.tree_id = $1
	ORDER BY n.node_id
	LIMIT 1;
$_$;


ALTER FUNCTION biosql.pdb_node_label_to_id(integer, text) OWNER TO postgres;

--
-- Name: pdb_node_label_to_id(integer, text[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_label_to_id(integer, text[]) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
	--$1 node label
	--$2 tree id	
	SELECT n.node_id
	FROM biosql.node n
	WHERE n.label = ANY($2)
	AND   n.tree_id = $1
	ORDER BY n.node_id;
$_$;


ALTER FUNCTION biosql.pdb_node_label_to_id(integer, text[]) OWNER TO postgres;

--
-- Name: pdb_node_qualifier(integer, text); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_qualifier(integer, text) RETURNS text
    LANGUAGE sql
    AS $_$

	SELECT eq.value
	FROM biosql.node np,
	biosql.node nc,
	biosql.edge e,
	biosql.edge_qualifier_value eq,
	biosql.term t
	WHERE eq.term_id = t.term_id
	AND e.edge_id = eq.edge_id
	AND e.parent_node_id = np.node_id
	AND e.child_node_id = nc.node_id
	AND e.child_node_id = $1
	AND t.name = $2
	LIMIT 1;
	
$_$;


ALTER FUNCTION biosql.pdb_node_qualifier(integer, text) OWNER TO postgres;

--
-- Name: pdb_node_tree(integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_node_tree(integer) RETURNS integer
    LANGUAGE sql
    AS $_$
	SELECT tree_id 
	FROM biosql.node n 
	WHERE n.node_id = $1

$_$;


ALTER FUNCTION biosql.pdb_node_tree(integer) OWNER TO postgres;

--
-- Name: pdb_num_childern(integer, text, integer[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_num_childern(integer, text, integer[]) RETURNS bigint
    LANGUAGE sql
    AS $_$
	
	SELECT COUNT(*)
	FROM biosql.node_path np, biosql.node n
	WHERE np.parent_node_id = n.node_id
	AND n.label = $2
	AND np.child_node_id = ANY($3)
	AND np.distance = 1
	AND n.tree_id = $1;
$_$;


ALTER FUNCTION biosql.pdb_num_childern(integer, text, integer[]) OWNER TO postgres;

--
-- Name: pdb_num_children(integer, integer[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_num_children(integer, integer[]) RETURNS bigint
    LANGUAGE sql
    AS $_$
	
	SELECT COUNT(*)
	FROM biosql.node_path np
	WHERE np.parent_node_id = $1
	AND np.child_node_id = ANY($2)
	AND np.distance = 1;
$_$;


ALTER FUNCTION biosql.pdb_num_children(integer, integer[]) OWNER TO postgres;

--
-- Name: pdb_num_children(integer[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_num_children(integer[]) RETURNS SETOF record
    LANGUAGE sql
    AS $_$
	
	SELECT n.node_id, COUNT(e.child_node_id)
	FROM biosql.node n, biosql.edge e
	WHERE n.node_id = e.parent_node_id
	AND e.child_node_id = ANY($1)
	GROUP BY n.node_id;
$_$;


ALTER FUNCTION biosql.pdb_num_children(integer[]) OWNER TO postgres;

--
-- Name: pdb_subtree_ab_exclude_c(integer, integer, integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_subtree_ab_exclude_c(integer, integer, integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
	SELECT e.edge_id 
	FROM biosql.node_path p, biosql.edge e, biosql.node pt, biosql.node ch 
	WHERE 
	    e.child_node_id = p.child_node_id
	AND pt.node_id = e.parent_node_id
	AND ch.node_id = e.child_node_id
	AND p.parent_node_id IN (
	      SELECT pA.parent_node_id
	      FROM   biosql.node_path pA, biosql.node_path pB
	      WHERE pA.parent_node_id = pB.parent_node_id
	      AND   pA.child_node_id = $1 
	      AND   pB.child_node_id = $2
	)
	AND NOT EXISTS (
	    SELECT 1 FROM biosql.node_path np
	    WHERE 
		np.child_node_id  = $3
	    AND np.parent_node_id = p.parent_node_id
	)
	$_$;


ALTER FUNCTION biosql.pdb_subtree_ab_exclude_c(integer, integer, integer) OWNER TO postgres;

--
-- Name: pdb_tree_ab_exclude_c(text, text, text); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_tree_ab_exclude_c(text, text, text) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
	SELECT DISTINCT t.tree_id
	FROM biosql.tree t, biosql.node_path p, biosql.node lca
	WHERE
	    p.parent_node_id = lca.node_id
	AND lca.tree_id = t.tree_id
	AND lca.node_id = (
	      SELECT pA.parent_node_id
	      FROM   biosql.node_path pA, biosql.node_path pB, biosql.node A, biosql.node B
	      WHERE pA.parent_node_id = pB.parent_node_id
	      AND   pA.child_node_id = A.node_id
	      AND   pB.child_node_id = B.node_id
	      AND   A.label = $1
	      AND   B.label = $2
	      AND   A.tree_id = t.tree_id
	      AND   B.tree_id = t.tree_id
	      ORDER BY pA.distance
	      LIMIT 1
	)
	AND NOT EXISTS (
	    SELECT 1 FROM biosql.node C, biosql.node_path np
	    WHERE 
		np.child_node_id = C.node_id
	    AND np.parent_node_id = p.parent_node_id
	    AND C.label = $3
	);$_$;


ALTER FUNCTION biosql.pdb_tree_ab_exclude_c(text, text, text) OWNER TO postgres;

--
-- Name: pdb_tree_ab_include_c(text, text, text); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_tree_ab_include_c(text, text, text) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
	SELECT t.tree_id
	FROM biosql.tree t, biosql.node_path p, biosql.node C
	WHERE
	    p.child_node_id = C.node_id
	AND C.tree_id = t.tree_id
	AND p.parent_node_id = (
	      SELECT pA.parent_node_id
	      FROM   biosql.node_path pA, biosql.node_path pB, biosql.node A, biosql.node B
	      WHERE pA.parent_node_id = pB.parent_node_id
	      AND   pA.child_node_id = A.node_id
	      AND   pB.child_node_id = B.node_id
	      AND   A.label = $1
	      AND   B.label = $2
	      AND   A.tree_id = t.tree_id
	      AND   B.tree_id = t.tree_id
	      ORDER BY pA.distance
	      LIMIT 1
	)
	AND C.label = $3
	;$_$;


ALTER FUNCTION biosql.pdb_tree_ab_include_c(text, text, text) OWNER TO postgres;

--
-- Name: pdb_tree_delete(integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_tree_delete(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$

	BEGIN

	DELETE
	FROM biosql.edge_qualifier_value eq
	WHERE eq.edge_id
	IN (
	SELECT biosql.tree_edges($1)
	);

	DELETE
	FROM biosql.edge e
	WHERE e.edge_id
	IN (
	SELECT biosql.tree_edges($1)
	);

	DELETE
	FROM biosql.node_qualifier_value nq
	WHERE nq.node_id
	IN (
	SELECT n.node_id
	FROM biosql.node n
	WHERE n.tree_id = $1
	);

	DELETE
	FROM node_path np
	WHERE np.child_node_id
	IN (
	SELECT n.node_id
	FROM biosql.node n
	WHERE n.tree_id = $1
	UNION
	SELECT t.node_id
	FROM biosql.tree t
	WHERE t.tree_id = $1	
	);
	
	DELETE FROM biosql.node WHERE tree_id = $1;

	DELETE FROM biosql.tree WHERE tree_id = $1;

	END;
	
$_$;


ALTER FUNCTION biosql.pdb_tree_delete(integer) OWNER TO postgres;

--
-- Name: pdb_tree_edge(integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_tree_edge(integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
	
	SELECT e.edge_id 
	FROM biosql.edge e, biosql.node pt, biosql.node ch 
	WHERE 
	    pt.tree_id = $1
	AND pt.node_id = e.parent_node_id
	AND ch.node_id = e.child_node_id
	
	$_$;


ALTER FUNCTION biosql.pdb_tree_edge(integer) OWNER TO postgres;

--
-- Name: pdb_tree_edge_qualifier(integer); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_tree_edge_qualifier(integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
	
	SELECT DISTINCT t.term_id
	FROM biosql.term t, biosql.node n, biosql.edge e, biosql.edge_qualifier_value eq
	WHERE eq.term_id = t.term_id
	AND e.edge_id = eq.edge_id
	AND (e.parent_node_id = n.node_id
	OR e.child_node_id = n.node_id)
	AND n.tree_id = $1;
$_$;


ALTER FUNCTION biosql.pdb_tree_edge_qualifier(integer) OWNER TO postgres;

--
-- Name: pdb_tree_include_label(text[]); Type: FUNCTION; Schema: biosql; Owner: postgres
--

CREATE FUNCTION pdb_tree_include_label(text[]) RETURNS SETOF integer
    LANGUAGE plpgsql
    AS $_$

	DECLARE
		trees	INTEGER;
	BEGIN
		FOR trees in 
		SELECT t.tree_id
		FROM biosql.tree t, biosql.node q
		WHERE q.label = ANY($1) 
		AND q.tree_id = t.tree_id
		GROUP BY t.tree_id
		LOOP
		RETURN NEXT trees;
		END LOOP;
	END;

$_$;


ALTER FUNCTION biosql.pdb_tree_include_label(text[]) OWNER TO postgres;
