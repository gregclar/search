#  Name object methods
class Name < ActiveRecord::Base
  self.table_name = "name"
  self.primary_key = "id"
  acts_as_tree
  belongs_to :author
  belongs_to :rank, class_name: "NameRank", foreign_key: "name_rank_id"
  belongs_to :status, class_name: "NameStatus", foreign_key: "name_status_id"
  belongs_to :name_type
  belongs_to :namespace
  has_many :instances
  has_many :instance_types, through: :instances
  has_many :references, through: :instances
  has_many :synonyms, through: :instances
  has_many :authors, through: :references
  has_many :tree_nodes
  has_many :name_tree_paths

  has_many :apni_tree_arrangements, through: :apni_name_tree_paths
  has_many :apni_name_tree_paths, class_name: "NameTreePath"

  has_many :apc_tree_nodes, -> { where "next_node_id is null and checked_in_at_id is not null" },
           class_name: "TreeNode"
  has_many :apc_tree_arrangements, through: :apc_tree_nodes

  has_one :apc_accepted_tree_node, -> { where "next_node_id is null and checked_in_at_id is not null and type_uri_id_part = 'ApcConcept'" },
           class_name: "TreeNode"
  has_one :apc_accepted_instance, through: :apc_accepted_tree_node

  has_one :apc_excluded_tree_node, -> { where "next_node_id is null and checked_in_at_id is not null and type_uri_id_part = 'ApcExcluded'" },
           class_name: "TreeNode"
  has_one :apc_excluded_instance, through: :apc_excluded_tree_node

  has_many :cited_by_instances, through: :instances
  has_many :cited_by_names, through: :cited_by_instances
  has_many :cited_by_instance_tree_nodes, through: :cited_by_instances
  has_many :cited_by_instance_tree_arrangements, through: :cited_by_instance_tree_nodes

  has_many :cited_by_instance_tree_node_names, through: :cited_by_instance_tree_nodes
  has_many :cited_by_instance_tree_node_name_name_tree_paths, through: :cited_by_instances

  has_one :accepted_name, foreign_key: :id
  has_many :name_instances, foreign_key: :id

  scope :not_a_duplicate, -> { where(duplicate_of_id: nil) }
  scope :has_an_instance, -> { where(["exists (select null from instance where name.id = instance.name_id)"]) }
  scope :lower_full_name_like, ->(string) { where("lower(f_unaccent(name.full_name)) like f_unaccent(?) ", string.tr("*", "%").downcase) }
  scope :lower_simple_name_like, ->(string) { where("lower(name.simple_name) like ? ", string.gsub(/\*/, "%").downcase) }
  scope :ordered, -> { order("sort_name") }
  scope :limited_high, -> { limit(5000) }

  def self.simple_name_allow_for_hybrids_like(string)
    where("( lower(name.simple_name) like ? or lower(name.simple_name) like ?)",
          string.downcase.tr("*", "%").tr("×", "x"),
          Name.string_for_possible_hybrids(string)
         )
  end

  def self.full_name_allow_for_hybrids_like(string)
    where("( lower(f_unaccent(name.full_name)) like ? or lower(f_unaccent(name.full_name)) like ?)",
          string.downcase.tr("*", "%").tr("×", "x"),
          Name.string_for_possible_hybrids(string)
         )
  end

  def self.string_for_possible_hybrids(string)
    string.downcase.tr("*", "%").sub(/^([^x])/, 'x \1').tr("×", "x")
  end

  # Setting up the final few associations got tricky.
  def self.unordered_accepted_tree_synonyms
    Name.joins(:cited_by_instance_tree_arrangements)
        .joins(:cited_by_instance_tree_node_names)
        .joins("inner join name_tree_path ntp on cited_by_instance_tree_node_names_name.id = ntp.name_id")
        .joins(" inner join tree_arrangement ntp_ta on ntp.tree_id = ntp_ta.id and ntp_ta.label = 'APC' ")
        .includes(:status)
        .includes(:cited_by_instance_tree_node_names)
        .joins(:rank)
        .joins(:name_type)
  end

  def self.new_unordered_accepted_tree_synonyms
    Name.joins(:rank)
        .joins(:cited_by_names)
        .joins(:apc_tree_arrangements)
        .joins(:name_type)
        .includes(:status)
  end

  def self.accepted_tree_synonyms
    Name.unordered_accepted_tree_synonyms.order("sort_name")
  end

  def instances_in_order
    self.instances.sort do |x, y|
      x.sort_fields <=> y.sort_fields
    end
  end

  def self.scientific_search
    Name.not_a_duplicate
        .has_an_instance
        .includes(:status)
        .includes(:rank)
        .order("sort_name")
  end

  def self.scientific_search_detailed
    Name.not_a_duplicate
        .has_an_instance
        .includes(:status)
        .includes(:rank)
        .includes(:instances)
        .includes(:instance_types)
        .includes(:references)
        .includes(:authors)
        .includes(:synonyms)
        .order("sort_name")
        # .includes(:accepted_name) # goes crazy on list search
  end

  def self.common_search
    Name.not_a_duplicate
        .has_an_instance
        .includes(:status)
        .order("sort_name")
  end

  def self.cultivar_search
    Name.not_a_duplicate
        .has_an_instance
        .includes(:status)
        .order("sort_name")
  end

  def self.all_search
    Name.limited_high
        .not_a_duplicate
        .has_an_instance
        .includes(:status)
        .includes(:rank)
        .order("sort_name")
  end

  def self.unordered_accepted_tree_search
    Name.includes(:status)
        .includes(:rank)
        .joins(:apc_tree_arrangements)
        .joins(:name_type)
  end

  def self.accepted_tree_search
    Name.unordered_accepted_tree_search.order("name.sort_name")
  end

  def self.xaccepted_tree_accepted_search
    Name.accepted_tree_search
        .where(" tree_node.type_uri_id_part = 'ApcConcept'")
  end

  def self.accepted_tree_accepted_search
    AcceptedName.simple_name_like(search_term)
  end

  def self.accepted_tree_excluded_search
    Name.accepted_tree_search
        .where(" tree_node.type_uri_id_part = 'ApcExcluded'")
  end

  def self.xaccepted_tree_accepted_or_excluded_search
    Name.accepted_tree_search
        .where(" tree_node.type_uri_id_part in ('ApcExcluded', 'ApcConcept')")
  end

  # "Union with Active Record"
  # http://thepugautomatic.com/2014/08/union-with-active-record/
  #
  # Gets past this error: ERROR:  bind message supplies 0 parameters, but prepared statement "" requires 2
  # See the explanation here: https://github.com/rails/rails/issues/13686
  def self.xaccepted_tree_all_simple_name_search(search_term = 'x')
    query1 = Name.unordered_accepted_tree_search
                 .where(" tree_node.type_uri_id_part in ('ApcExcluded', 'ApcConcept')")
                 .joins(:name_type)
                 .includes(:rank)
                 .lower_simple_name_like(search_term)
    query2 = Name.unordered_accepted_tree_synonyms
                 .lower_simple_name_like(search_term)
    # Get a real bind value instead of "$1" in the generated SQL.
    sql = Name.connection.unprepared_statement {
      "((#{query1.to_sql}) UNION (#{query2.to_sql})) AS name"
    }
    # Could not order by name_rank.sort_order
    # .order("name_rank.sort_order, name.full_name")
    # Sorting produced an array
    ##Name.from(sql).sort {|x,y| x.rank.sort_order <=> y.rank.sort_order}
    Name.from(sql).sort {|x,y| x.sort_key <=> y.sort_key}
  end

  # "Union with Active Record"
  # http://thepugautomatic.com/2014/08/union-with-active-record/
  #
  # Gets past this error: ERROR:  bind message supplies 0 parameters, but prepared statement "" requires 2
  # See the explanation here: https://github.com/rails/rails/issues/13686
  def self.xaccepted_tree_all_full_name_search(search_term = 'x')
    query1 = Name.unordered_accepted_tree_search
                 .where(" tree_node.type_uri_id_part in ('ApcExcluded', 'ApcConcept')")
                 .joins(:name_type)
                 .includes(:rank)
                 .lower_full_name_like(search_term)
    query2 = Name.unordered_accepted_tree_synonyms
                 .lower_full_name_like(search_term)
    # Get a real bind value instead of "$1" in the generated SQL.
    sql = Name.connection.unprepared_statement {
      "((#{query1.to_sql}) UNION (#{query2.to_sql})) AS name"
    }
    # Could not order by name_rank.sort_order
    # .order("name_rank.sort_order, name.full_name")
    # Sorting produces an array
    #
    #Name.from(sql).sort {|x,y| x.rank.sort_order <=> y.rank.sort_order}
    Name.from(sql).sort {|x,y| x.sort_key <=> y.sort_key}
  end

  def family?
    rank.family?
  end

  def family_name
    n = self
    Name.seek_family_name(n)
  end

  def self.seek_family_name(n)
    if n.blank?
      ""
    elsif n.family?
      n.full_name
    else
      n = n.parent
      Name.seek_family_name(n)
    end
  end

  def apc?
    TreeNode.apc?(full_name)
  end

  def apc_instance_id
    #TreeNode.apc(full_name).try("first").try("instance_id")
    AcceptedName.where(id: id)
  end

  def pg_descendants
    rid = id
    Name.join_recursive do
      start_with(id: rid)
        .connect_by(id: :parent_id)
        .order_siblings(:full_name)
        .nocycle
    end
  end

  # Built as pg-specific code (although should be standard sql)
  # Originally tried "tn.parent_id = #{id}" but this was slow
  # (~1200ms vs ~3ms) despite an index on parent_id.
  def pg_ranked_descendant_counts
    sql = "WITH RECURSIVE nodes_cte(id, full_name, parent_id, depth, path) AS (
 SELECT tn.id, tn.full_name, tn.parent_id, 1::INT AS depth,
        tn.id::TEXT AS path, tnr.name as rank, tnr.sort_order rank_order
   FROM name AS tn
        join
        name_rank tnr
        on tn.name_rank_id = tnr.id
  WHERE tn.id = #{ActiveRecord::Base.sanitize(id)}
UNION ALL
 SELECT c.id, c.full_name, c.parent_id, p.depth + 1 AS depth,
        (p.path || '->' || c.id::TEXT), cnr.name as rank,
        cnr.sort_order rank_order
   FROM nodes_cte AS p, name AS c
        join name_rank cnr
        on c.name_rank_id = cnr.id
  WHERE c.parent_id = p.id
)
 SELECT n.rank, count(*) FROM nodes_cte AS n
 where exists (select null from instance where instance.name_id = n.id)
   and n.id != #{ActiveRecord::Base.sanitize(id)}
  group by n.rank, n.rank_order
  order by n.rank_order"
  ActiveRecord::Base.connection.execute(sql)
  end

  def pg_descendants_at_rank(rank_name)
    sql = "WITH RECURSIVE nodes_cte(id, full_name, parent_id, depth, path) AS (
 SELECT tn.id, tn.full_name, tn.parent_id, 1::INT AS depth,
        tn.id::TEXT AS path, tnr.name as rank, tnr.sort_order rank_order
   FROM name AS tn
        join
        name_rank tnr
        on tn.name_rank_id = tnr.id
  WHERE tn.id = #{ActiveRecord::Base.sanitize(id)}
UNION ALL
 SELECT c.id, c.full_name, c.parent_id, p.depth + 1 AS depth,
        (p.path || '->' || c.id::TEXT),
        cnr.name as rank, cnr.sort_order rank_order
   FROM nodes_cte AS p, name AS c
        join name_rank cnr
        on c.name_rank_id = cnr.id
  WHERE c.parent_id = p.id
)
SELECT n.id, n.full_name FROM nodes_cte AS n
       inner join
       name_tree_path ntp
       on n.id = ntp.name_id
       inner join
       tree_arrangement ta
       on ta.id = ntp.tree_id
  where n.rank = #{ActiveRecord::Base.sanitize(rank_name)}
    and ta.label = 'APNI'
    and exists (select null from instance where instance.name_id = n.id)
  order by n.full_name"
  ActiveRecord::Base.connection.execute(sql)
  end

  def sub_taxon?
    sql = "WITH RECURSIVE nodes_cte(id, full_name, parent_id, depth, path) AS (
 SELECT tn.id, tn.full_name, tn.parent_id, 1::INT AS depth,
        tn.id::TEXT AS path, tnr.name as rank, tnr.sort_order rank_order
   FROM name AS tn
        join
        name_rank tnr
        on tn.name_rank_id = tnr.id
  WHERE tn.id = #{id}
UNION ALL
 SELECT c.id, c.full_name, c.parent_id, p.depth + 1 AS depth,
        (p.path || '->' || c.id::TEXT),
        cnr.name as rank, cnr.sort_order rank_order
   FROM nodes_cte AS p, name AS c
        join name_rank cnr
        on c.name_rank_id = cnr.id
  WHERE c.parent_id = p.id
)
SELECT 1 FROM nodes_cte AS n
  where exists (select null from instance where instance.name_id = n.id)
limit 3"
    results = ActiveRecord::Base.connection.execute(sql)
    max = 0
    results.each_with_index do |result, index|
      max = index
    end
    Rails.logger.debug("max: #{max}")
    if max <= 1
      return false
    else
      return true
    end
  end

  def show_status?
    status.show?
  end

  def as_json(options = {})
    case options[:show] 
    when :details
      [name: full_name, status: status.name]
    else
      [name: full_name, status: status.name]
    end
  end

  def to_csv
    attributes.values_at(*Name.columns.map(&:name))
    [full_name, status.name].to_csv
  end

  def self.csv_headings
    ["full_name", "status"].to_csv
  end

  def apc_accepted?
    apc_accepted_instance.present?
  end

  def apc_excluded?
    apc_excluded_instance.present?
  end

  def apc_comment
    return unless apc_accepted?
    apc_accepted_instance.apc_comment
  end

  def apc_distribution
    return unless apc_accepted?
    apc_accepted_instance.apc_distribution
  end

  # For compatibility with name_instance_vw.
  def status_name
    status.name
  end
end
